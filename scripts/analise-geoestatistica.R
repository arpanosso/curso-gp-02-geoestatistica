### Introdução à Geoestatística
## Instalar pacotes, se necessários
# install.packages("nome-do-pacote")

## Carregar os pacotes, super necessário
library(tidyverse)
library(sp)
library(gstat)
library(corrplot)
source("../R/my-functions.R")

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

## VOLTEMOS À APRESENTAÇÃO
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

## VOLTEMOS À APRESENTAÇÃO

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

## Crie o gráfico de dispersão para MO com ela mesma, no lag 1
# cada lag equivale a 50 m.
transecto <- read_rds("../data/transecto.rds")
glimpse(transecto)
transecto |>
  filter( y == 0) |>
  ggplot(aes(x=x,y=arg)) +
  geom_line() +
  theme_bw()

## Para o estudo da autocorrelação vamos carregar um banco de dados
# sobre a textura do solo com pontos dispostes em transectos
# de 50 m de distância de separação entre eles.
transecto <- read_rds("data/transecto.rds")
glimpse(transecto)
transecto |>
  filter( y == 0) |>
  ggplot(aes(x=x,y=arg)) +
  geom_line() +
  theme_bw()

## Para exemplificar, vamos olhar a matriz decorrelação contruída
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
