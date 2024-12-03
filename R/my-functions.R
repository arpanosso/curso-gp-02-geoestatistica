# Criar uma função para a estatística descritiva
my_estat_desc <- function(x){
  n <- length(x)
  media <- mean(x, na.rm=TRUE)
  variancia <- var(x, na.rm = TRUE)
  desv_pad <- sd(x, na.rm = TRUE)
  c(n, media, variancia, desv_pad) # retorno da função
}

# Criar um lag específico em um vetor
create_lag <- function(column, lag){
  n <- length(column)
  nvec <- c(rep(NA,lag),column[1:(n-lag)])
  return(nvec)
}
