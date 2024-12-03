# lendo o arquivo do excel
dados <- readxl::read_xlsx("data-raw/geo_fco2.xlsx")
dplyr::glimpse(dados)

# corrigindo o nomes das colunas
dados <- janitor::clean_names(dados)
dplyr::glimpse(dados)

# Salvando os dados na pasta data no formato rds
readr::write_rds(dados,"data/geo_fco2.rds")

# lendo o arquivo do excel
dados <- read.table("data-raw/transectos.txt",h=TRUE)
dplyr::glimpse(dados)

# corrigindo o nomes das colunas
dados <- janitor::clean_names(dados)
dplyr::glimpse(dados)

# Salvando os dados na pasta data no formato rds
readr::write_rds(dados,"data/transecto.rds")
