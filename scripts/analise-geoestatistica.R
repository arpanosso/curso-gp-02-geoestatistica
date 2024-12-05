### Introdução à Geoestatística
## Instalar pacotes, se necessários
# install.packages("nome-do-pacote")

## Carregar os pacotes, super necessário
library(tidyverse)
library(sp)
library(gstat)
library(corrplot)
source("R/my-functions.R")

## Ler o banco de dados
dados_geo <- read_rds("data/geo_fco2.rds") # lenitura
glimpse(dados_geo) # resumo do arquivo
skimr::skim(dados_geo) # resumo dos dados

## Identificando os nomes das áreas (coluna tratamento)
dados_geo |>
  pull(tratamento) |>
  unique()

## Filtrar do banco de dados, selecionar somente as observações
# referentes à área de eucalipto.
dados_geo_eu <- dados_geo |>
  filter(tratamento == "EU")

## Inspecionar a malha amostral.
dados_geo_eu |>
  ggplot(aes(x=x, y=y)) +
  geom_point() +
  theme_bw()

## Mapear o teor de matéria orgânica do solo (MO)
# pelo tamanho e a cor dos marcadores de pontos.
dados_geo_eu |>
  mutate(
    mo_class = cut(mo,4)
  ) |>
  ggplot(aes(x=x, y=y, color=mo_class, size=mo_class)) +
  geom_point() +
  theme_bw() +
  scale_color_viridis_d()

## Calcular as estatísticas descritivas dos dados de MO.
dados_geo_eu |>
  summarise(
    N = n(),
    Media = mean(mo, na.rm = TRUE),
    Mediana = median(mo, na.rm = TRUE),
    Menor = min(mo, na.rm = TRUE),
    Maior = max(mo, na.rm = TRUE),
    Variancia = var(mo, na.rm = TRUE),
    Desvio_Padrao = sd(mo, na.rm = TRUE),
    Assimetria = agricolae::skewness(mo),
    Curtose = agricolae::kurtosis(mo),
    CV = 100*Desvio_Padrao/Media
  ) |> t()

############################
## VOLTEMOS À APRESENTAÇÃO #
############################
## Crie o histograma da variável `mo`, adicionando
# adicionando os valores de `média`, `mediana`,
# `primeiro` e `terceiro quartil`.
mo_qnt <- dados_geo_eu |>
  pull(mo) |>
  summary() # median()  mean()

## Crie o gráfico Quantil-Quantil (QQ-plot) para
# auxiliar a interpretação da normalidade.
dados_geo_eu |>
  ggplot(aes(sample = mo)) +
  stat_qq() +
  stat_qq_line(color="blue",lwd=2) +
  theme_bw()

## Realize o teste de normalidade dos dados para `mo`.
dados_geo_eu |>
  pull(mo) |>
  shapiro.test() # teste de normalidade

## Verifique a presença de tendência nos dados em função das
# coordenadas ao longo dos eixos `x` e `y`.
dados_geo_eu |>
  ggplot(aes(x=x, y=mo)) +
  geom_point() +
  theme_bw()

dados_geo_eu |>
  ggplot(aes(x=y, y=mo)) +
  geom_point() +
  theme_bw()

## Realize a análise de regressão linear entre mo e as
# coordenadas x e y.
dados_geo_eu |>
  lm(formula = mo ~ x) |>
  summary.lm()

dados_geo_eu |>
  lm(formula = mo ~ y) |>
  summary.lm()

############################
## VOLTEMOS À APRESENTAÇÃO #
############################
## Crie a matriz de correlação linear entre todas as variáveis
# numéricas do banco de dados.
dados_geo_eu |>
  select(fco2:k) |>
  cor()

dados_geo_eu |>
  select(fco2:k) |>
  cor() |>
  corrplot(method = "ellipse",
           type = "upper")

## Para o estudo da autocorrelação vamos carregar um banco de dados
# sobre a textura do solo com pontos dispostos em transectos
# de 50 m de distância de separação entre eles.
transecto <- read_rds("data/transecto.rds")
glimpse(transecto)
transecto |>
  filter( y == 0) |>
  ggplot(aes(x=x,y=arg)) +
  geom_line() +
  theme_bw()

## Para exemplificar, vamos olhar a matriz de correlação contruída
# a partir da variável argila com ela mesma em diverentes lags.
transecto |>
  filter( y == 0) |>
  select(x,arg) |>
  mutate(
    arg_lag_1 = create_lag(arg,1),
    arg_lag_3 = create_lag(arg,3),
    arg_lag_5 = create_lag(arg,5),
    arg_lag_7 = create_lag(arg,7),
    arg_lag_9 = create_lag(arg,9),
    arg_lag_11 = create_lag(arg,11),
    arg_lag_13 = create_lag(arg,13),
    arg_lag_15 = create_lag(arg,15),
    arg_lag_17 = create_lag(arg,17)
  ) |>
  drop_na() |>
  select(-x) |>
  cor() |>
  corrplot(type = "upper")

## Vamos construir um semivariograma experimental:
# Inicialmente vamos extrair os vetores `x`, `y` e `z`,
# onde z será nossa variáviel MO.
x <- dados_geo_eu |>  pull(x)
y <- dados_geo_eu |>  pull(y)
z <- dados_geo_eu |>  pull(mo)

## Devemos agora construir as matrizes de distância e a
# matriz de valor de gamma (variância).
matriz_dist <- matrix(0,ncol=102,nrow=102)
matriz_gamma <- matrix(0,ncol=102,nrow=102)


## Calcular a matriz de distância entre todos os pontos amostrais
# e a matriz de valores de gamma.
for(i in 1:102){
  for(j in 1:102){
    matriz_dist[i,j] = sqrt((x[i]-x[j])^2 + (y[i]-y[j])^2)
    matriz_gamma[i,j] = (z[i]-z[j])^2
  }
}


table(matriz_dist) %/% 2 |>
  plot()
abline(h=30, col="red", lty =2)
# E recomenda-se um número de pares de ponto em uma dada
# distância de separação h sempre maior que 30.

## Calcule h, N_h e gamma.
n_lags <- 5
active_lag_distance <- 60
h <- seq(5, active_lag_distance, n_lags)
n_h <- h
gamma_h <- h
for(i in seq_along(h)){
  if(i == 1){
    filtro <- matriz_dist > 0 & matriz_dist <= h[i]
  }else{
    filtro <- matriz_dist > h[i-1] & matriz_dist <= h[i]
  }
  n_h[i] <- sum(filtro)/2
  gamma_h [i] <- sum(matriz_gamma[filtro])/2/n_h[i]/2
}

## Construa o semivariograma experimental h vs gamma.
tibble(n_h,h,gamma_h) |>
  ggplot(aes(x=h,y=gamma_h)) +
  geom_point(size=3) +
  theme_bw()

## Construção do semivariograma pela função variogram do
# pacote gstat
# Recorte do banco de dados com x, y, e z
df_aux <- dados_geo_eu |>
  select(x, y, mo) |>
  rename(z = mo)
class(df_aux)

## Deve-se passar df_aux para SpatialData uma vez que
# as funções do gstat trabalham com esse formato de objeto
coordinates(df_aux) = ~ x + y
head(df_aux)
class(df_aux)

# criando a fórmula para o semivariograma
form <- z ~ 1

# criar o semivarigrama experimental
semi_exp <- variogram(form, df_aux,
                             cutoff=60,
                             width = 5)
semi_exp |>
  ggplot(aes(x=dist, y=gamma)) +
  geom_point(size=3) +
  theme_bw() +
  annotate("text",
           x=semi_exp$dist,
           y=semi_exp$gamma*0.98,
           label = semi_exp$np)

## Modelagem - Modelo Esférico
mod_ajust <- fit.variogram(semi_exp,
                           vgm(model = "Sph",
                               nugget=15,
                               psill=30,
                               range=20)
)
texto_par <- get_mod_par_stat(semi_exp,mod_ajust)
semi_exp |>
  ggplot(aes(x=dist, y=gamma)) +
  geom_point(size=3) +
  theme_bw()+
  geom_line(data = variogramLine(mod_ajust,
                                 maxdist = 60),
            aes(x=dist, y=gamma),
            color="red") +
  annotate("text",x=50,
           y=seq(22.5,10,-2.5),
           label = texto_par,size=6)


## Crie a região de adensamento, ou seja, um novo arquivo
# contendo a posição geográfica (pares de coordenadas) onde
# será realizada a estimativa via krigagem ordinária.
dados_geo_eu |>
  ggplot(aes(x=x,y=y)) +
  geom_point() +
  theme_bw()

menor_dist <- 1
grid_adensado <- expand.grid(
  x=seq(0,100,menor_dist),
  y=seq(0,100,menor_dist)
)

dados_geo_eu |>
  ggplot(aes(x=x,y=y)) +
  geom_point() +
  geom_point( data = grid_adensado,
              aes(x=x,y=y),
              color="blue",
              size=1) +
  theme_bw()

## transformar o grid_adensado em um objeto
# SpatiaData
coordinates(grid_adensado) = ~ x+ y

## Utilizando o algoritmo da KO, vamos estimar o atributo nos
# locais não amostrados (gradeado adensado).
ko <- gstat::krige(form, df_aux,grid_adensado,
                   mod_ajust,
                   block=c(0.1,0.1))

## Apresente os padrões espaciais (mapa de ko) e o mapa
# da estimativa do erro.
ko |>
  as_tibble() |>
  ggplot(aes(x=x,y=y)) +
  geom_tile(aes(fill= var1.pred)) +
  scale_fill_viridis_c() +
  labs(title = "FCO2") +
  theme_bw() +
  labs(fill="MO")
