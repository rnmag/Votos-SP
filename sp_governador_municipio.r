library(tidyverse)
library(sf)
library(jsonlite)


# Configuracao dos municipios ---------------------------------------------

urlm <- "https://resultados.tse.jus.br/oficial/ele2022/544/config/mun-e000544-cm.json"
muni_tse <- fromJSON(urlm,
                     simplifyDataFrame = TRUE) %>%
  .[["abr"]] %>%
      unnest("mu", names_repair = "universal") %>%
      select(-c, -z) %>%
      set_names("uf", "estado", "cod_tse", "cod_ibge", "nome_municipio") %>%
      filter(uf == "SP")


# Dados -------------------------------------------------------------------

url_muni <- paste0("https://resultados.tse.jus.br/oficial/ele2022/546/dados/", str_to_lower(muni_tse$uf),
                  "/", str_to_lower(muni_tse$uf), muni_tse$cod_tse, "-c0003-e000546-v.json")

municipios <- map(url_muni, function(x) {
  fromJSON(x, simplifyDataFrame = TRUE) %>%
    .[["abr"]] %>%
    tbl_df() %>%
    filter(tpabr == "MU")
})

# Votos válidos
final <- municipios %>%
  bind_rows() %>%
  unnest(cand, names_repair = "universal") %>%
  select(cdabr, vap, pvap, n) %>%
  rename(cod_tse = cdabr, votos_abs = vap, votos_perc = pvap, numero_candidato = n) %>%
  left_join(muni_tse) %>%
  select(uf, nome_municipio, cod_tse, cod_ibge, numero_candidato, votos_abs, votos_perc)

write_excel_csv2(final, "sp_governador_municipio.csv")

# Votos não válidos
nao_validos <- municipios %>%
    bind_rows() %>%
    unnest(cand, names_repair = "universal") %>%
    select(cdabr, a, pa, tvn, ptvn, vb, pvb) %>%
    rename(cod_tse = cdabr, abstencoes = a, p_abstencoes = pa, nulos = tvn, p_nulos = ptvn, brancos = vb, p_brancos = pvb) %>%
    left_join(muni_tse) %>%
    select(uf, nome_municipio, cod_tse, cod_ibge, abstencoes, p_abstencoes, nulos, p_nulos, brancos, p_brancos) %>%
    distinct()

 write_excel_csv2(nao_validos, "sp_nao_validos_municipio.csv")
