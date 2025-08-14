# Laboratório DevOps - Terraform + AWS

⚠️ **Projeto Educacional** - Este repositório é usado para fins didáticos e demonstra a implementação de infraestrutura como código (IaC) usando Terraform na AWS.

## Arquitetura

Este projeto provisiona uma infraestrutura completa na AWS contendo:

- **VPC** com subnets públicas e privadas em 2 AZs
- **Application Load Balancer (ALB)** para distribuição de tráfego
- **Instância EC2** com Nginx executando em subnet pública
- **RDS PostgreSQL** em subnets privadas
- **Security Groups** configurados adequadamente
- **CI/CD** via GitHub Actions

## Pré-requisitos

- AWS CLI configurado com permissões administrativas
- Conta AWS ativa
- Git instalado

## 1. Configuração Inicial do Backend S3

Primeiro, crie um bucket S3 para armazenar o estado do Terraform:

```bash
# Substitua <meu-projeto-tfstates> ou use um nome único globalmente
export BUCKET_NAME="meu-projeto-tfstates-$(date +%s)"

# Criar o bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1

# Bloquear acesso público
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Habilitar criptografia
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Bucket criado: $BUCKET_NAME"
```

## 2. Preparação da Chave SSH

Para permitir acesso SSH às instâncias EC2:

```bash
# Gerar par de chaves SSH
ssh-keygen -t rsa -b 2048 -f ~/.ssh/devops-lab -N ""

# Importar chave pública para AWS
aws ec2 import-key-pair \
  --key-name "devops-lab-key" \
  --public-key-material fileb://~/.ssh/devops-lab.pub \
  --region sa-east-1

# Descobrir seu IP público
curl ifconfig.me
# Exemplo: se retornar 203.0.113.45, use 203.0.113.45/32 nos secrets
```

## 3. Configuração do Role OIDC (Opcional - para GitHub Actions)

Se quiser usar GitHub Actions, crie um role OIDC:

```bash
# Criar política de confiança
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:SEU_USUARIO/SEU_REPOSITORIO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Criar o role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Anexar política administrativa (apenas para laboratório)
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Obter ARN do role
aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
```

## 4. Configuração dos GitHub Secrets

No seu repositório GitHub, configure os seguintes secrets em `Settings > Secrets and variables > Actions`:

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `DB_PASSWORD` | Senha do banco PostgreSQL | `MinhaSenh@123!` |
| `TF_STATE_BUCKET` | Nome do bucket S3 | `meu-projeto-tfstates-1234567890` |
| `TF_STATE_KEY` | Chave do estado no S3 | `terraform/devops-it.tfstate` |
| `AWS_ROLE_TO_ASSUME` | ARN do role OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `SSH_KEY_NAME` | Nome da chave SSH na AWS | `devops-lab-key` |
| `MY_IP_CIDR` | Seu IP público em CIDR | `203.0.113.45/32` |

## 5. Execução Local (Alternativa ao GitHub Actions)

### Clone o repositório
```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
```

### Configure o backend
```bash
# Edite o arquivo backend.hcl com o nome do seu bucket
cat > backend.hcl <<EOF
bucket  = "seu-bucket-name-aqui"
key     = "terraform/devops-it.tfstate"
region  = "sa-east-1"
encrypt = true
EOF
```

### Execute o Terraform
```bash
# Inicializar
terraform init -backend-config=backend.hcl

# Planejar (será solicitada a senha do banco)
terraform plan

# Aplicar
terraform apply
```

### Acessar a aplicação
Após o deploy, acesse a aplicação usando o DNS do Load Balancer:
```bash
terraform output alb_dns_name
```

### Acessar via SSH
```bash
# Conectar à instância EC2 via SSH
ssh -i ~/.ssh/devops-lab ec2-user@$(terraform output -raw ec2_public_ip)
```

## 6. Limpeza dos Recursos

Para evitar custos, sempre destrua os recursos após os testes:

```bash
terraform destroy
```

## 7. Estrutura do Projeto

```
.
├── .github/workflows/
│   └── deploy.yml           # Pipeline CI/CD
├── modules/
│   ├── network/             # Módulo VPC e redes
│   ├── web/                 # Módulo ALB e EC2
│   └── db/                  # Módulo RDS PostgreSQL
├── user_data/
│   └── al2023_nginx.sh      # Script de inicialização EC2
├── main.tf                  # Configuração principal
├── variables.tf             # Variáveis de entrada
├── outputs.tf               # Saídas do Terraform
├── providers.tf             # Provedores e backend
├── data.tf                  # Fontes de dados
└── backend.hcl              # Configuração do backend S3
```

## Recursos Criados

- 1 VPC com 4 subnets (2 públicas, 2 privadas)
- 1 Internet Gateway e Route Tables
- 1 Application Load Balancer
- 1 Instância EC2 com Nginx
- 1 Banco RDS PostgreSQL
- Security Groups configurados
- Target Group e Listener para ALB

## Contribuição

Este é um projeto educacional. Sinta-se livre para fazer fork e experimentar!