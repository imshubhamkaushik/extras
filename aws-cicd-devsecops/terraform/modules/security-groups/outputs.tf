output "alb_sg" { 
    value = aws_security_group.alb.id 
}
output "eks_nodes_sg" { 
    value = aws_security_group.eks_nodes.id 
    }
output "jenkins_sg" { 
    value = aws_security_group.jenkins.id 
    }
output "sonar_sg" { 
    value = aws_security_group.sonar.id 
    }
output "rds_sg" { 
    value = aws_security_group.rds.id 
    }