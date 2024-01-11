# Instalar pacotes necessários
# install.packages("tidyverse")
# install.packages("sp")
# install.packages("gstat")
# install.packages("corrplot")
# install.packages("skimr")
# install.packages("agricolae")

# Carregar os pacotes
library(tidyverse)
library(sp)
library(gstat)
library(corrplot)
source("R/my-functions.R")

# Lendo o banco de dados
dados_geo <- read_rds("data/geo_fco2.rds")
glimpse(dados_geo)
skimr::skim(dados_geo)

# Número de categorias de tratamentos
dados_geo |>
  pull(tratamento) |>
  unique()

# Filtrar as observações para o tratamento "EU"
dados_geo |>
  filter(tratamento == "EU")

# Apresentando o gradeado amostral
dados_geo |>
  filter(tratamento == "EU") |>
  ggplot(aes(x=x, y=y)) +
  geom_point() +
  theme_bw()

# Mapear o tamanho e a cor dos marcadores em função de fco2
dados_geo |>
  filter(tratamento == "EU") |>
  mutate(
    fco2_class = cut(fco2,4)
  ) |>
  ggplot(aes(x=x, y=y, color=fco2_class, size=fco2_class)) +
  geom_point() +
  theme_bw() +
  scale_color_viridis_d()

# Mostrar os dois gradeados....
dados_geo |>
  mutate(
    fco2_class = cut(fco2,4)
  ) |>
  ggplot(aes(x=x, y=y,
             color=fco2_class,
             size=fco2_class)) +
  geom_point() +
  theme_bw() +
  scale_color_viridis_d() +
  facet_wrap(~tratamento)

# Estatísticas Descritivas para fco2
dados_geo |>
  filter(tratamento == "EU") |>
  summarise(
    N = n(),
    Media = mean(fco2, na.rm = TRUE),
    Mediana = median(fco2, na.rm = TRUE),
    Menor = min(fco2, na.rm = TRUE),
    Maior = max(fco2, na.rm = TRUE),
    Variancia = var(fco2, na.rm = TRUE),
    Desvio_Padrao = sd(fco2, na.rm = TRUE),
    Assimetria = agricolae::skewness(fco2),
    Curtose = agricolae::kurtosis(fco2),
    CV = 100*Desvio_Padrao/Media
  )

# Estatística Descritiva para várias variáveis
dados_geo |>
  filter(tratamento == "EU") |>
  summarise(
    across(
      fco2:k, my_estat_desc
    )
  )

# Testando as pressuposições da análise geoestatística
## Normalidade dos Dados
# Histograma da variável regionalizada
dados_geo |>
  filter(tratamento == "EU") |>
  pull(fco2) |>
  quantile() # median()  mean()

dados_geo |>
  filter(tratamento == "EU") |>
  ggplot(aes(x=fco2)) +
  geom_histogram(bins=15,fill="lightgray",color="black") +
  theme_bw() +
  geom_vline(xintercept = c(4.65, 4.53, 3.67, 5.36),
             linetype=2,
             color= c("red","blue" ,"blue" ,"blue"),
             lwd = 1)

# Construir o gráfico QQ-Plot, quanto mais próximo os pontos
# da reta 1:1, mais próximo a distribuição dos dados está da
# distribuição normal.
dados_geo |>
  filter(tratamento == "EU") |>
  ggplot(aes(sample = fco2)) +
  stat_qq() +
  stat_qq_line(color="blue",lwd=2) +
  theme_bw()

# Teste de Normalidade
dados_geo |>
  filter(tratamento == "EU") |>
  pull(fco2) |>
  shapiro.test() # teste de normalidade

# Rejeitamos H0 ao nível de 1% de significência e concluímos
# que os dados de FCO2 não seguem uma distribuição normal
# para a área de eucalipto.
# Para FCO2, apesar da leve fuga da normalidade, vamos
# optar pela não transformação dos dados durante a continuidade
# das análises.

## Estacionaridade da média.
# Gráfico de dispersão entre X e fco2
dados_geo |>
  filter(tratamento == "EU") |>
  ggplot(aes(x=x, y=fco2)) +
  geom_point() +
  theme_bw()

# Análise de regressão entre x e fco2
dados_geo |>
  filter(tratamento == "EU") |>
  lm(formula = fco2 ~ x) |>
  summary.lm()


# Gráfico de dispersão entre y e fco2
dados_geo |>
  filter(tratamento == "EU") |>
  ggplot(aes(x=y, y=fco2)) +
  geom_point() +
  theme_bw()

# Análise de regresão entre y e fco2
dados_geo |>
  filter(tratamento == "EU") |>
  lm(formula = fco2 ~ y) |>
  summary.lm()

# Correlação
# medida da intensidade da relação linear entre os
# atributos do banco de dados
dados_geo |>
  filter(tratamento == "EU") |>
  select(fco2:k) |>
  plot()

dados_geo |>
  filter(tratamento == "EU") |>
  select(fco2:k) |>
  cor() |>
  corrplot(method = "ellipse",
           type = "upper")

dados_geo |>
  filter(tratamento == "EU") |>
  select(fco2:k) |>
  GGally::ggpairs() +
  theme_bw()

## Construir o Semivariograma
## Estrair o vetor x, y, e z
x <- dados_geo |>
  filter(tratamento == "EU") |>
  pull(x)

y <- dados_geo |>
  filter(tratamento == "EU") |>
  pull(y)

z <- dados_geo |>
  filter(tratamento == "EU") |>
  pull(fco2)

## Construir as matrizes de distâncias entre pontos e a
## matriz gamma que receberá os valores calculados de
## [z(xi) - z(xi+h)]^2
matriz_dist <- matrix(0,ncol=102,nrow=102)
matriz_gamma <- matrix(0,ncol=102,nrow=102)

# Calcular a matriz de distância
for(i in 1:102){
  for(j in 1:102){
    matriz_dist[i,j] = sqrt((x[i]-x[j])^2 + (y[i]-y[j])^2)
    matriz_gamma[i,j] = (z[i]-z[j])^2
  }
}

table(matriz_dist) |>
  plot()
abline(h=30)

## Construção do Semivariograma experimental
lag <- 5
active_lag_distance <- 100
h <- seq(5, active_lag_distance, lag)
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
tibble(n_h,h,gamma_h) |>
  ggplot(aes(x=h,y=gamma_h)) +
  geom_point(size=3) +
  theme_bw()


gstat::variogram()














