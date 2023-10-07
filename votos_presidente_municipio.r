library(tidyverse)
library(sf)
library(jsonlite)


# Configuracao dos municipios ---------------------------------------------

urlm <- "https://resultados.tse.jus.br/oficial/ele2022/544/config/mun-e000544-cm.json"
muni_tse <- fromJSON(urlm,
                     simplifyDataFrame = TRUE) %>%
  .[["abr"]]  %>%
  unnest("mu", names_repair = "universal") %>%
  select(-c, -z) %>%
  set_names("uf", "estado", "cod_tse", "cod_ibge", "nome_municipio")


# Dados -------------------------------------------------------------------

url_muni <- paste0("https://resultados.tse.jus.br/oficial/ele2022/544/dados/", str_to_lower(muni_tse$uf),
                  "/", str_to_lower(muni_tse$uf), muni_tse$cod_tse, "-c0001-e000544-v.json")

municipios <- map(url_muni, function(x) {
  fromJSON(x, simplifyDataFrame = TRUE) %>%
    .[["abr"]] %>%
    tbl_df() %>%
    filter(tpabr == "MU")
})

final <- municipios %>%
  bind_rows() %>%
  unnest(cand, names_repair = "universal") %>%
  select(cdabr, vap, pvap, n) %>%
  rename(cod_tse = cdabr, votos_abs = vap, votos_perc = pvap, numero_candidato = n) %>%
  left_join(muni_tse) %>%
  select(uf, nome_municipio, cod_tse, cod_ibge, numero_candidato, votos_abs, votos_perc)

write_excel_csv2(final, "votos_presidente_municipio.csv")
