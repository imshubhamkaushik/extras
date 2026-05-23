import getpass
import subprocess
import sys
from pathlib import Path
from utils.command import info, error, warn, run_command

# ---------------------------------------------------------------------------
# Path constants
# ---------------------------------------------------------------------------

ROOT_DIR            = Path(__file__).resolve().parents[2]
ANSIBLE_DIR         = ROOT_DIR / "ansible"
VAULT_PASSWORD_FILE = Path.home() / ".vault_pass"
VAULT_FILE          = ANSIBLE_DIR / "group_vars" / "all" / "vault.yaml"


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _write_vault_password_file(password: str) -> None:
    """Write password to ~/.vault_pass with owner-read-only permissions."""
    VAULT_PASSWORD_FILE.write_text(password)
    VAULT_PASSWORD_FILE.chmod(0o600)


def _is_vault_encrypted() -> bool:
    """
    Return True when vault.yaml starts with the $ANSIBLE_VAULT header.

    Why this check exists:
    - ansible-vault decrypt on an already-plaintext file returns exit code 1
      with a confusing error message.
    - Checking the header first gives a clear, early error instead of a
      cryptic ansible-vault failure mid-run.
    """
    if not VAULT_FILE.exists():
        return False
    return VAULT_FILE.read_text(errors="replace").startswith("$ANSIBLE_VAULT")


def _is_vault_password_valid() -> bool:
    """
    Return True when ~/.vault_pass can decrypt vault.yaml.

    Uses ansible-vault view (read-only, no file modification) and discards
    all output — we only care about the exit code.
    """
    if not VAULT_FILE.exists():
        return True  # nothing to validate against yet

    result = subprocess.run(
        ["ansible-vault", "view", str(VAULT_FILE),
         "--vault-password-file", str(VAULT_PASSWORD_FILE)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


# ---------------------------------------------------------------------------
# Vault password setup
# ---------------------------------------------------------------------------

def _prompt_for_vault_password() -> None:
    """
    Prompt for a non-empty vault password and persist it to ~/.vault_pass.
    Loops until a non-empty value is entered.
    """
    while True:
        password = getpass.getpass("Enter vault password: ")
        if password.strip():
            _write_vault_password_file(password)
            return
        warn("Password cannot be empty. Try again.")


def _create_vault_password_file() -> None:
    """
    Interactively create ~/.vault_pass with confirmation.

    Contract:
    - On success  : ~/.vault_pass exists and is written.
    - On any bad  : calls error() which exits the process.
      input         Callers do NOT need to check a return value.
    """
    print("")
    warn(f"Vault password file not found at {VAULT_PASSWORD_FILE}")
    warn("This file stores the password used to encrypt/decrypt your secrets vault.")
    print("")

    confirm = input("Create ~/.vault_pass now? (yes/no): ").strip().lower()
    if confirm not in ("yes", "y"):
        error(
            "Vault password file is required to run Ansible.\n"
            f"       Create it manually:\n"
            f"         echo 'your-password' > {VAULT_PASSWORD_FILE} && "
            f"chmod 600 {VAULT_PASSWORD_FILE}"
        )

    password         = getpass.getpass("Enter vault password: ")
    confirm_password = getpass.getpass("Confirm vault password: ")

    if not password.strip():
        error("Vault password cannot be empty.")
    if password != confirm_password:
        error("Passwords do not match. Re-run and try again.")

    _write_vault_password_file(password)
    print("")
    info(f"Vault password file created at {VAULT_PASSWORD_FILE}")


def _handle_invalid_vault_password() -> bool:
    """
    Prompt the user up to 3 times for the correct vault password.

    Returns:
        True  — correct password found, written to ~/.vault_pass.
        False — user chose to wipe the vault; old files are deleted.

    Calls error() (hard exit) if the user refuses to wipe after 3 failures.
    """
    attempts = 0
    while True:
        print("")
        _prompt_for_vault_password()

        if _is_vault_password_valid():
            info("Vault password is valid.")
            return True

        attempts += 1
        warn(f"Incorrect vault password (attempt {attempts}/3).")

        if attempts >= 3:
            print("")
            warn("Unable to decrypt vault after 3 attempts.")
            warn("The password may be incorrect or permanently lost.")
            confirm = input(
                "Recreate vault? This will DELETE all existing secrets. (yes/no): "
            ).strip().lower()

            if confirm in ("yes", "y"):
                VAULT_FILE.unlink(missing_ok=True)
                VAULT_PASSWORD_FILE.unlink(missing_ok=True)
                info("Old vault and password file deleted. Starting fresh.")
                return False

            error("Cannot proceed without a valid vault password.")


def _setup_vault_password_file() -> None:
    """
    Ensure ~/.vault_pass exists and can decrypt vault.yaml (when it exists).

    Decision tree
    ─────────────
    vault.yaml EXISTS
      └─ password file exists AND decrypts cleanly  →  nothing to do (fast path)
      └─ password file missing OR wrong password
           └─ prompt up to 3 times
                └─ correct  →  done
                └─ user wipes vault  →  create new password file
                                        (vault file created next in _setup_vault_file)

    vault.yaml does NOT exist
      └─ password file missing  →  create it now
                                   (vault file created next in _setup_vault_file)
      └─ password file exists   →  reuse it (will encrypt the new vault with it)
    """
    if VAULT_FILE.exists():
        if VAULT_PASSWORD_FILE.exists():
            info(f"Vault password file found at {VAULT_PASSWORD_FILE}")
            if _is_vault_password_valid():
                info("Vault password is valid.")
                return
            warn("Vault password does NOT match vault.yaml.")
        else:
            warn("vault.yaml exists but ~/.vault_pass is missing.")

        # Wrong or missing password — enter recovery loop.
        vault_survived = _handle_invalid_vault_password()
        # If vault was wiped (False), fall through to create a new password file.
        if not vault_survived:
            _create_vault_password_file()
        return

    # vault.yaml does not exist yet.
    if not VAULT_PASSWORD_FILE.exists():
        _create_vault_password_file()
    # Password file already exists → it will be used when encrypting the new vault.


# ---------------------------------------------------------------------------
# Vault file setup
# ---------------------------------------------------------------------------

def _prompt_secret(prompt: str, allow_empty: bool = False) -> str:
    """
    Prompt for a secret value with hidden input (getpass).
    Loops until a non-empty value is entered unless allow_empty is True.
    """
    while True:
        value = getpass.getpass(f"  {prompt}: ")
        if value.strip() or allow_empty:
            return value.strip()
        warn("Value cannot be empty. Try again.")


def _setup_vault_file() -> None:
    """
    Interactively create and encrypt group_vars/all/vault.yaml if it does
    not exist.

    Idempotent: exits immediately (with an info message) when the file is
    already present. Does NOT validate whether it is encrypted — that was
    already verified in _setup_vault_password_file().

    Secrets written
    ───────────────
    vault_jenkins_admin_password  — Jenkins admin user password
    vault_github_token            — GitHub personal access token
    vault_sonar_admin_password    — SonarQube admin password
    vault_sonar_token             — intentionally left empty; the SonarQube
                                    Ansible role generates a 'jenkins-token'
                                    in SonarQube and writes the plaintext
                                    value here after Phase 2 completes.
    """
    if VAULT_FILE.exists():
        info(f"Vault file already exists at {VAULT_FILE}")
        return

    print("")
    warn(f"Vault file not found at {VAULT_FILE}")
    warn("This file holds all encrypted secrets used by Ansible.")
    print("")

    confirm = input("Create and encrypt vault file now? (yes/no): ").strip().lower()
    if confirm not in ("yes", "y"):
        error(
            "Vault file is required to run Ansible.\n"
            "       Create it manually:\n"
            "         ansible-vault create ansible/group_vars/all/vault.yaml"
        )

    VAULT_FILE.parent.mkdir(parents=True, exist_ok=True)

    print("")
    info("Enter your secret values below (input is hidden):")
    print("")

    secrets = {
        "vault_jenkins_admin_password": _prompt_secret("Jenkins admin password"),
        "vault_github_token":           _prompt_secret("GitHub personal access token"),
        "vault_sonar_admin_password":   _prompt_secret("SonarQube admin password"),
        # Populated by the SonarQube Ansible role on first run (Phase 2).
        # Leave empty here — the role generates the token inside SonarQube,
        # then atomically writes it back into this encrypted file.
        "vault_sonar_token":            "",
    }

    lines = [
        "# Shared vault — loaded for ALL hosts via group_vars/all/vault.yaml",
        "# DO NOT EDIT MANUALLY — use: ansible-vault edit group_vars/all/vault.yaml",
        "",
        "# vault_sonar_token is intentionally empty on creation.",
        "# It is populated automatically by the sonarqube Ansible role on first run.",
        "",
    ]
    for key, value in secrets.items():
        lines.append(f'{key}: "{value}"')

    VAULT_FILE.write_text("\n".join(lines) + "\n")

    result = subprocess.run(
        ["ansible-vault", "encrypt", str(VAULT_FILE),
         "--vault-password-file", str(VAULT_PASSWORD_FILE)],
    )
    if result.returncode != 0:
        VAULT_FILE.unlink(missing_ok=True)
        error("ansible-vault encrypt failed. Is ansible-vault installed?")

    print("")
    info(f"Vault file created and encrypted at {VAULT_FILE}")


def check_vault() -> None:
    """
    Entry point for vault validation.
    Ensures ~/.vault_pass and vault.yaml both exist and are consistent.
    Always call this before running any playbook phase.
    """
    _setup_vault_password_file()
    _setup_vault_file()


# ---------------------------------------------------------------------------
# Playbook execution — Option 1: separate subprocess per phase
# ---------------------------------------------------------------------------

def _run_playbook(limit: str, step_label: str) -> None:
    """
    Run ansible-playbook scoped to one host group via --limit.

    WHY SEPARATE SUBPROCESSES (and not a single playbook run):
    ──────────────────────────────────────────────────────────
    Ansible loads ALL variables — including vault secrets — exactly once, at
    process startup, before any task executes.

    Problem this solves:
      Phase 2 (SonarQube) generates vault_sonar_token and writes it into
      vault.yaml on disk. But if Jenkins ran in the same ansible-playbook
      process, vault_sonar_token was already resolved to "" at startup —
      Ansible has no mechanism to retroactively re-resolve a variable for a
      play that already has its variable scope locked in.

    The fix:
      Each phase is a SEPARATE subprocess. Python's subprocess.run() blocks
      until ansible-playbook exits. When the next phase starts, it is a brand-
      new process that reads vault.yaml fresh from disk — so vault_sonar_token
      is already populated when Phase 3 (Jenkins) begins.

    This is not a hack. It is the standard pattern for multi-phase Ansible
    runs where an earlier phase produces a secret that a later phase consumes,
    without a dedicated secrets manager (Vault, AWS Secrets Manager, etc.).

    Args:
        limit:       Ansible --limit value, e.g. "sonarqube" or "jenkins".
                     Must exactly match a group name in aws_ec2.yaml.
        step_label:  Human-readable label printed before and after the run.
    """
    print("")
    info(f"[{step_label}] Starting — limit: {limit}")
    print("─" * 60)

    run_command(
        f"ansible-playbook playbook.yaml"
        f" --limit {limit}"
        f" --vault-password-file {VAULT_PASSWORD_FILE}",
        cwd=ANSIBLE_DIR,
    )

    print("─" * 60)
    info(f"[{step_label}] Completed successfully.")


def run_ansible() -> None:
    """
    Full provisioning sequence — three phases, three subprocesses.

    Phase 1  --limit all
      Targets every EC2 instance. Runs the 'common' and 'docker' roles:
      baseline apt packages, timezone, Docker CE, user group membership.
      Both the Jenkins and SonarQube hosts need Docker before their own
      roles run, so this must come first.

    Phase 2  --limit sonarqube
      Runs the 'sonarqube' role exclusively on the SonarQube EC2:
      - Starts the SonarQube container (community.docker.docker_container).
      - Waits for SonarQube to be healthy (polls /api/system/status).
      - Changes the default admin password idempotently.
      - Generates a SonarQube user token named 'jenkins-token' (skips if
        vault_sonar_token is already populated — idempotent).
      - Atomically writes vault_sonar_token into the encrypted vault.yaml
        on the Ansible control node (localhost delegate, single shell task
        that decrypts → edits → re-encrypts without leaving the file
        plaintext at any point).
      - Creates the Jenkins webhook in SonarQube (idempotent — skips if a
        webhook named 'Jenkins' already exists).

    Phase 3  --limit jenkins
      Fresh subprocess → vault.yaml re-read from disk → vault_sonar_token
      is now populated. Runs 'devops-tools' and 'jenkins' roles:
      - Installs Java, Jenkins, plugins via jenkins-plugin-cli.
      - Renders /etc/default/jenkins from jenkins_defaults.j2 (all secrets
        injected as environment variables — JCasC reads them via ${VAR}).
      - Deploys jcasc.yaml which configures: admin user, SonarQube server,
        GitHub/SonarQube credentials, and pipeline job definitions.
      - Triggers a JCasC reload via the Jenkins API so config is live without
        a full restart.
      - Verifies admin login (HTTP 200 from /api/json) to confirm JCasC
        applied cleanly.
    """
    print("")
    info("Ansible Provisioning — Starting")
    print("")

    confirm = input(
        "This will provision EC2 instances via Ansible. Proceed? (yes/no): "
    ).strip().lower()
    if confirm not in ("yes", "y"):
        info("Aborted by user.")
        return

    # ── Pre-flight: vault ────────────────────────────────────────────────────
    print("")
    info("Pre-flight: checking Ansible Vault...")
    check_vault()

    # ── Dependency check: ansible-galaxy ────────────────────────────────────
    print("")
    info("Installing Ansible Galaxy collections (idempotent)...")
    run_command(
        "ansible-galaxy collection install -r requirements.yaml",
        cwd=ANSIBLE_DIR,
    )

    # ── Phase 1: common baseline on all hosts ───────────────────────────────
    _run_playbook(
        limit="all",
        step_label="Phase 1/3 — Common baseline (all hosts)",
    )

    # ── Phase 2: SonarQube ───────────────────────────────────────────────────
    # Generates jenkins-token in SonarQube and writes vault_sonar_token to
    # vault.yaml on disk before Phase 3 starts.
    _run_playbook(
        limit="sonarqube",
        step_label="Phase 2/3 — SonarQube configuration",
    )

    # ── Phase 3: Jenkins ─────────────────────────────────────────────────────
    # New subprocess → vault.yaml re-read from disk → vault_sonar_token is
    # populated → JCasC renders sonarqube-token credential with a real value.
    _run_playbook(
        limit="jenkins",
        step_label="Phase 3/3 — Jenkins configuration",
    )

    print("")
    info("Ansible Provisioning — Complete.")
    print("")
    info("Access Jenkins at the URL printed above.")
    info("SonarQube is available on its private IP via Jenkins as a jump host.")