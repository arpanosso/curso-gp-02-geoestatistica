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

# parametros do semivariograma
get_mod_par_stat <- function(.variogram, .mod){
  modelo <-as.character(.mod$model[[2]])
  sse <- attr(.mod, "SSErr") # soma quadrados resíduos
  nugget <- .mod$psill[1] # efeito pepita C0
  sill <- sum(.mod$psill) # patamar C0 + C1
  range <- .mod$range[2] # alcance
  dist <- .variogram$dist
  gamma <- .variogram$gamma
  rs_total <- (gamma - mean(gamma))^2
  if(modelo == "Sph"){
    gamma_pred <- ifelse(dist <= range, nugget + (sill-nugget)*(3/2*(dist/range)-1/2*(dist/range)^3),sill)
  }
  if(modelo == "Exp"){
    gamma_pred <- nugget + (sill-nugget)*(1-exp(-3*(dist/(range*3))))
  }
  if(modelo == "Gau"){
    gamma_pred <- nugget + (sill-nugget)*(1-exp(-3*(dist/(range*(3^.5)))^2))
  }

  rs_mod <- (gamma - gamma_pred)^2
  r2 <- (sum(rs_total)-sum(rs_mod))/sum(rs_total)

  vout <- paste0(c("model","c0","c0+c1","a","sse","r2"),
                 " = ",
                 c(modelo, round(c(nugget,sill,range,sse,r2),3))
  )
  return(vout)
}
