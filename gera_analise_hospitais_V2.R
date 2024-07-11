# Limpa o ambiente
rm(list = ls())

# Carrega/instala conjuto de pacotes que geralmente utilizo
pacotes = c(
  "tidyverse", "readxl", "dplyr", "stringr", "xgboost",
  "wooldridge", "lmtest", "faraway", "stargazer", "randomForest",
  "ggplot2", "tseries", "car", "corrplot", "PerformanceAnalytics", 
  "caret", "rmarkdown", "glmnet", "neuralnet", "e1071", "gbm", "rpart",
  "httr", "jsonlite", "data.table", "basedosdados", "ggmap", "geosphere",
  "sf", "osmdata", "tmaptools", "mapsapi", "writexl", "openxlsx"
)


# Instala pacotes que ainda não estão instalados
for (x in pacotes) {
  if (!x %in% installed.packages()) {
    install.packages(x, repos = "http://cran.us.r-project.org")
  }
}

# Carrega os pacotes
lapply(pacotes, require, character.only = TRUE)
rm(pacotes, x)



# --------------------------- Importando dados -------------------------------- #

# Defina o caminho para o arquivo
file_path <- "C:/Users/super/Downloads/dataset.xlsx"

# Liste as planilhas disponíveis no arquivo
sheet_names <- excel_sheets(file_path)

# Importe a planilha desejada (por exemplo, a primeira planilha)
df <- read_excel(file_path, sheet = sheet_names[1])


# ------------------------- funcoes uteis --------------------------------------#
to_lowercase_df <- function(df) {
  # Converte os nomes das colunas para minúsculas
  colnames(df) <- tolower(colnames(df))
  
  # Aplica a função tolower a todas as colunas que são de tipo character ou factor
  df[] <- lapply(df, function(col) {
    if (is.character(col)) {
      return(tolower(col))
    } else if (is.factor(col)) {
      return(factor(tolower(as.character(col))))
    } else {
      return(col)
    }
  })
  return(df)
}

# Função para padronizar datas
padronizar_data <- function(data) {
  # Tentativa de parsing de diferentes formatos de data
  data_formatada <- parse_date_time(data, orders = c("dmy", "dmy", "dmy"))

  # Convertendo para o formato 'dia/mês/ano'
  data_formatada <- format(data_formatada, "%d/%m/%Y")

  return(data_formatada)
}


replace_special_characters <- function(df) {
  # Função para remover acentos e substituir "ç" por "c"
  remove_accent <- function(text) {
    text <- gsub("ç", "c", text)
    text <- gsub("Ç", "C", text)
    text <- iconv(text, to = "ASCII//TRANSLIT")
    text <- gsub("[^[:alnum:]_]", "", text)  # Remove caracteres especiais, mantendo letras e números
    return(text)
  }
  
  # Obter os nomes das colunas do data frame
  col_names <- colnames(df)
  
  # Aplicar a função de remoção de acentos
  col_names <- sapply(col_names, remove_accent)
  
  # Atribuir os novos nomes ao data frame
  colnames(df) <- col_names
  
  return(df)
}

transformar_maiusculas <- function(df, coluna) {
  # Verificar se a coluna existe no data frame
  if (!(coluna %in% colnames(df))) {
    stop("A coluna especificada não existe no data frame.")
  }
  
  # Transformar a coluna em maiúsculas
  df <- df %>%
    mutate(!!sym(coluna) := toupper(!!sym(coluna)))
  
  return(df)
}

# ------------- Tratamento da base de dados -----------------------------------#


# Padroniza para minusculo os nomes de colunas
df_alt <-  to_lowercase_df(df)

# Padroniza caracteres especiais substituindo-os
df_alt <- replace_special_characters(df_alt)

# Checando possiveis duplicacoes
dup <- duplicated(df_alt) | duplicated(df_alt, fromLast = TRUE)

# Mostra duplicacoes se houverem
dup_check <- df_alt[dup, ]
# Sem duplicacoes

# Renomeia variaveis
df_alt <- df_alt %>% 
  rename(nm_hosp = "nomedohospital",
         tipo_atend = "tipodeatendimento",
         serv_emerg = "realizaservicosdeemergencia",
         ctr_PES = "atendeaoscriteriosdeusodeprontuarioeletronico",
         aval_loc = "avaliacaodolocal",
         nvl_mort = "comparacaonacionaldemortalidade",
         nvl_seg_cuid = "comparacaonacionaldesegurancadoscuidados",
         nvl_readim = "comparacaonacionaldereadmissao",
         nvl_satisf = "comparacaonacionaldaexperienciadopaciente",
         efi_cuid = "eficaciadacomparacaonacionaldecuidados",
         op_atend = "oportunidadedeatendimentocomparacaonacional",
         efi_img_medic = "usoeficientedecomparacaonacionaldeimagensmedicas")


# Filtrando apenas hospitais que seguem os critérios basicos de analise
df_alt1 <- df_alt %>% 
  filter(ctr_PES == "true",
         status == "true",
         serv_emerg == "true")

# Filtrar apenas os registros com a data mais recente
df_alt <- df_alt1 %>%
  group_by(id) %>%
  filter(data == max(data))  # Filtrar para manter apenas a data mais recente por id

# Identificar registros excluídos
excluidos <- anti_join(df_alt1, df_alt, by = NULL)  # Encontrar registros exclusivos de df_alt


# Faz uma contagem de hospitais ativos por municipio
cont_cit <- df_alt %>% 
 group_by(cidade, status) %>% 
  summarise(contagem = n()) %>% 
  arrange(desc(contagem)) 

# As 03 cidades com maior numero de hospitais ativos sao respectivamente: Sao Paulo, Rio de Janeiro e Salvador

df_alt <- df_alt %>%
  filter(cidade %in% c("sao paulo", "rio de janeiro", "salvador"))

# # Ajustando variaveis de indicadores


# Ordem de prioridade de variaveis de uso hospitalar
# Foi consultado artigos da oms falando sobre escores de uso hospitalar, gestão de saúde e também a opinião de médicos atuantes.

# Justificativa:

## 1 - Segurança da informação do hospital:
# A importância desse item se justifica pelo principio do sigilo médico. Vazamentos de dados
# e informações de paciente e profissionais que atuaram no cuidado de pessoas são graves e comprometem
# a integridade do local de trabalho e ferem a ética de trabalho. 

# 2 - Mortalidade no hospital:
# As taxas de mortalidade hospitalar devem ser avaliadas pela determinação de causas evitáveis como 
# forma de delimitar e propor educação continuada para os profissionais que ali atuam. 

# 3 - Readmissão hospitalar:
# o retorno de pacientes logo após a alta hospitalar é sinal de que talves a alta tenha sido indicada de 
# forma precoce, fazendo valer a reavaliação do quadro em que o paciente se encontrava, buscando discutir 
# os casos como forma de compreender e melhorar o processo de trabalho. 

# 4 - Experiência do paciente: 
# Períodos de internação hospitalar tem por objetivo estabilizar um quadro de saúde que tenha sido agravado 
# por algum motivo. No entanto, coloca-se a pessoa num ambiente estranho e com rotinas fora do seu habitual.
# Assim, avaliar o que o paciente compreendeu da necessidade de internação e quais suas percepções do que pode
# ser melhorado pode gerar reflxões nos profissionais de saúde para tornar o cuidado mais humano. 

# 5 - Cuidados com o paciente: Reavaliar como foi a forma de cuidado de uma pessoa durante um período de internação,
# embora seja importante, não é prático de ser feito. Cada paciente recebe o cuidado indicado e existe o princípio da 
# equidade que precisa ser respeitado. Duas pessoas com patologias parecidas talvez não recebam o mesmo cuidado em certos
# aspectos por necessitarem de abordagens diferentes. 

# 6 - Oportunidade de atendimento:
# Acesso oportuno a serviços de saúde é essencial para prevenir o agravamento de quadros e garantir um atendimento adequado.

# 7 - Utilização eficiente de imagens médicas:
# O uso adequado de exames de imagem otimiza o diagnóstico, reduz custos e melhora a qualidade do cuidado.

## Ordem de prioridade e peso:

# # 1. Segurança da informação 
# # 2. Mortalidade no hospital 
# # 3. Readmissão hospitalar 
# # 4. Cuidados com o paciente 
# # 5. Experiência do paciente 
# # 6. Oportunidade de atendimento 
# # 7. Utilização eficiênciente de imagens médicas 
# 
# Mapear categorias qualitativas para números
df_alt <- df_alt %>%
  mutate(
    nvl_seg_cuid = case_when(
      tolower(nvl_seg_cuid) == "acima da média nacional" ~ 3,
      tolower(nvl_seg_cuid) == "igual à média nacional" ~ 2,
      tolower(nvl_seg_cuid) == "abaixo da média nacional" ~ 1,
      TRUE ~ NA_real_
    ),
    nvl_mort = case_when(
      tolower(nvl_mort) == "acima da média nacional" ~ 1,
      tolower(nvl_mort) == "igual à média nacional" ~ 2,
      tolower(nvl_mort) == "abaixo da média nacional" ~ 3,
      TRUE ~ NA_real_
    ),
    nvl_readim = case_when(
      tolower(nvl_readim) == "acima da média nacional" ~ 1,
      tolower(nvl_readim) == "igual à média nacional" ~ 2,
      tolower(nvl_readim) == "abaixo da média nacional" ~ 3,
      TRUE ~ NA_real_
    ),
    efi_cuid = case_when(
      tolower(efi_cuid) == "acima da média nacional" ~ 3,
      tolower(efi_cuid) == "igual à média nacional" ~ 2,
      tolower(efi_cuid) == "abaixo da média nacional" ~ 1,
      TRUE ~ NA_real_
    ),
    nvl_satisf = case_when(
      tolower(nvl_satisf) == "acima da média nacional" ~ 3,
      tolower(nvl_satisf) == "igual à média nacional" ~ 2,
      tolower(nvl_satisf) == "abaixo da média nacional" ~ 1,
      TRUE ~ NA_real_
    ),
    op_atend = case_when(
      tolower(op_atend) == "acima da média nacional" ~ 3,
      tolower(op_atend) == "igual à média nacional" ~ 2,
      tolower(op_atend) == "abaixo da média nacional" ~ 1,
      TRUE ~ NA_real_
    ),
    efi_img_medic = case_when(
      tolower(efi_img_medic) == "acima da média nacional" ~ 3,
      tolower(efi_img_medic) == "igual à média nacional" ~ 2,
      tolower(efi_img_medic) == "abaixo da média nacional" ~ 1,
      TRUE ~ NA_real_
    )
  )

# # Calcuala o resultado geral
# df_alt <- df_alt %>%
#   rowwise() %>%
#   mutate(resultado_geral = case_when(
#     nvl_seg_cuid == 1 | nvl_mort == 1 | nvl_readim == 1 ~ "péssimo",
#     nvl_seg_cuid == 3 & nvl_mort == 3 & nvl_readim == 3 & efi_cuid == 3 & nvl_satisf == 3 & op_atend == 3 & efi_img_medic == 3 ~ "excelente",
#     nvl_seg_cuid == 3 & nvl_mort == 3 & nvl_readim == 3 ~ "muito bom",
#     nvl_seg_cuid == 3 & nvl_mort != 3 & nvl_readim != 3 ~ "bom",
#     nvl_mort == 3 & nvl_seg_cuid != 3 & nvl_readim != 3 ~ "regular",
#     nvl_readim == 3 & nvl_seg_cuid != 3 & nvl_mort != 3 ~ "mediano",
#     sum(c_across(c(nvl_seg_cuid, nvl_mort, nvl_readim)) == 3) >= 2 & sum(c_across(c(efi_cuid, nvl_satisf, op_atend, efi_img_medic)) == 1) >= 1 ~ "bom",
#     TRUE ~ "péssimo"
#   ))

# CREIO QUE ESSA ABORDAGEM DE ATRIBUIR NOTAS E PESOS SEJA MAIS ASSERTIVA
# Calcular a média geral usando a fórmula ajustada
df_alt <- df_alt %>%
  mutate(resultado_geral = ((nvl_mort * 2.5) + (nvl_seg_cuid * 3) + (efi_img_medic * 2.25) +
                              (nvl_satisf * 1.75) + (efi_cuid * 1.50) + (op_atend * 1.35) +
                              ( nvl_readim* 1.15)) / 13.5)  # Dividir pela soma dos pesos




# Checa a distribuicao de hospistais com notas aceitaveis
xtabs(~resultado_geral, df_alt)

# # Filtra apenas hospitais "mediano", bom", "muito bom" e "excelente"
# # e remove varaiveis desnecessaria no momento
# 
# hosp_qualit <- df_alt %>%
#   filter(resultado_geral %in% c( "bom", "muito bom", "excelente")) %>%
#   select(-cep, -tipo_atend, -serv_emerg, -ctr_PES, -status)

# Filtra apenas os municipios com a melhor avaliacao local para as 3 cidades selecionadas
hosp_qualit <- df_alt %>%
  group_by(municipio) %>%
  arrange(desc(resultado_geral), .by_group = TRUE) %>%
  slice_head(n = 6) %>%
  ungroup()


# Usa minha key api do maps
register_google(key = "api_key")

# Obtendo geocod (lat, lon) dos hospitais com base no endereco
hosp_qualit$geocode <- geocode(hosp_qualit$endereco)

# Splita latitude e longitude eem variaveis diferentes
hosp_qualit$lat <- hosp_qualit$geocode$lat
hosp_qualit$lon <- hosp_qualit$geocode$lon

# Remover a coluna geocode se não for mais necessária
hosp_qualit$geocode <- NULL


# Endereço da empresa
endereco_empresa <- "Alameda Santos, 415 - Vila Mariana, São Paulo - SP, 01418-100"
coords_empresa <- geocode(endereco_empresa)

# Calcule a distância entre a empresa e cada hospital
hosp_qualit <- hosp_qualit %>%
  mutate(distancia_km = distGeo(
    matrix(c(lon, lat), ncol = 2),
    matrix(c(coords_empresa$lon, coords_empresa$lat), ncol = 2)
  ) / 1000)  # Convertendo de metros para quilômetros

# Calcula tempo de distancia entre a empresa e os hospitais

# Velocidade média de deslocamento por carro
velocidade_media_kmh <- 80  # Assumindo uma velocidade média de 80 km/h

# Velocidade média de voo
velocidade_media_voo_kmh <- 600  # Assumindo uma velocidade média de voo de 600 km/h

# Calcula tempo de deslocamento por via terrestre e aere em casos de maiores distancias
hosp_qualit <- hosp_qualit %>%
  mutate(
    # Calcular o tempo de deslocamento por carro em minutos
    tempo_desloc_carro_minutos = (distancia_km / velocidade_media_kmh) * 60,
    horas_carro = floor(tempo_desloc_carro_minutos / 60),
    minutos_carro = round(tempo_desloc_carro_minutos %% 60),
    tempo_desloc_carro = sprintf("%02d:%02d", horas_carro, minutos_carro),
    
    # Calcular o tempo de deslocamento por voo em minutos
    tempo_desloc_voo_minutos = (distancia_km / velocidade_media_voo_kmh) * 60,
    horas_voo = floor(tempo_desloc_voo_minutos / 60),
    minutos_voo = round(tempo_desloc_voo_minutos %% 60),
    tempo_desloc_voo = sprintf("%02d:%02d", horas_voo, minutos_voo)
  ) %>% 
  select(-tempo_desloc_carro_minutos, -horas_carro, -minutos_carro, 
         -tempo_desloc_voo_minutos, -horas_voo, -minutos_voo, -lat, -lon)

# Arredonda as varaiveis distancia e tempo de deslocamento
hosp_qualit <- hosp_qualit %>%
  mutate(distancia_km = round(distancia_km, 3))

# Filtra objetos por estado/cidade

# Sao Paulo
hosp_sp <- hosp_qualit %>%
  filter(estado == "sp") %>%
  select(-cep, -tipo_atend, -serv_emerg,
         -ctr_PES, -status, -endereco, -data) %>% 
  relocate(resultado_geral, distancia_km, tempo_desloc_carro, .after = aval_loc)

# Rio de Janeiro
hosp_rj <- hosp_qualit %>%
  filter(estado == "rj") %>%
  select(-cep, -tipo_atend, -serv_emerg,
         -ctr_PES, -status, -endereco, -data) %>% 
  relocate(resultado_geral, distancia_km, tempo_desloc_carro, .after = aval_loc)

# Salvador
hosp_sa <- hosp_qualit %>%
  filter(estado == "ba") %>%
  select(-cep, -tipo_atend, -serv_emerg,
         -ctr_PES, -status, -endereco, -data) %>% 
  relocate(resultado_geral, distancia_km, tempo_desloc_carro, .after = aval_loc)




## ANALISE DO MELHOR HOSPITAL PARA CADA CIDADE ##

# Identificação de 1 principal hospital de cada cidade com o melhor resultado "Geral",

#### Sao Paulo:


# top 3 hospitais selecionados com base no resultado geral:
# 70013
# 70523
# 70543

hosp_sp_top_3 <- hosp_sp %>%
  filter(id %in% c("70013", "70523", "70543"))


## ORDEM DE INTEGRACAO PARA A CIDADE DE SP

# 1.lugar: Hospital do Coracao              ## PRIORITARIO PARA INTEGRACAO ##
# id: 70013
# Nota geral: 3.0
# distancia e tempo de deslocamento: 599m e 1 minuto ou menos

# 2. lugar: hospital ruben berta
# id: 70543
# Nota geral: 2.57
# distancia e tempo de deslocamento: 3,6 km e 5 minutos ou menos

# 3. lugar: hosp central de guaianazes
# id: 70523
# Nota geral: 2.59
# distancia e tempo de deslocamento: 25,4km e 20 minutos






### Rio de Janeiro:

# top 3 hospitais selecionados com base no resultado geral:
# 70066
# 70118
# 70458

hosp_rj_top_3 <- hosp_rj %>% 
  filter(id %in% c("70066", "70118", "70458"))

# 1º lugar:   hospital norte dor     ## PRIORITARIO PARA INTEGRACAO ##
# id: 70066
# Nota geral: 2.381481
# distancia e tempo de deslocamento: 348.1km e 04h :21m


# 2. lugar: hospital de iraja
# id: 70118
# Nota geral: 2.333333
# distancia e tempo de deslocamento: 349.6km e 04h :22m


# 3. lugar: ordem terceira do carmo
# id: 70443
# Nota geral: 2.318519
# distancia e tempo de deslocamento: 362.1km e 04h :32m






### Salvador

# top 3 hospitais selecionados com base no resultado geral:
# 70769
# 70776
# 70785

hosp_sa_top_3 <- hosp_sa %>% 
  filter(id %in% c("70769", "70776", "70785"))

# 1º lugar:  cardio pulmonar da bahia           ## PRIORITARIO PARA INTEGRACAO
# id: 70769
# Nota geral: 2.340741
# distancia e tempo de deslocamento: 1451.4km 18h:09 minutos

# 2º lugar:  hospital da sagrada familia
# id: 70785
# Nota geral: 2.177778
# distancia e tempo de deslocamento: 1458.022km e 18h:14 minutos

# 3º lugar:  cto medico agenor paiva
# id: 70776
# Nota geral: 2.177778
# distancia e tempo de deslocamento:  1458.074km e 18h:14 minutos












### ------------------- ANALISE EXPLORATORIA DOS DADOS ----------------------####


# Calcula a proporção de NA por variavel
prop_missing <- sapply(df_alt1, function(x) sum(is.na(x)) / length(x)) * 100
prop_missing <- prop_missing[-which(names(prop_missing) == "resultado_geral")]

# Grafico de barras para a proporção de NAs
ggplot(data.frame(names = names(prop_missing), proporcao = prop_missing), aes(x = names, y = proporcao)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = paste0(round(proporcao, 1), "%")), vjust = -0.3, size = 3.5) + # Adiciona rótulos de valores em percentual
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5)
  ) +
  labs(
    title = "Proporção de NA's por variável",
    x = "Variáveis",
    y = "Percentual de NA's"
  )

# Após calcula a proporção de NA's podemos ter uma investigação mais afundp sobre.
# Os valores faltantes se concetram na variaveis sobre resultados sobre indicadores hospitalares
# os maiores percentuais de dados faltantes ficaram com as variaveis de segurança de informaçao hospitalar
# com 24,9% dos dados. Seguido pela variavel de indicador de eficiencia do uso da imagem médica com 20,2%.
# Ambos com percentuais  relativamente elevados. As demais variaveis com dados faltantes são todas sobre indicadores hospitalares
# com valores na faixa de 5 a 6%. A variavel que demonstrou menor proporção de faltantes foi a variavel do indicador de
# readmissão hospitalar, felizmente sendo uma variavel de suma importancia na avaliacao e com poucas lacunas de informacoes.

# a proporçao de dados faltantes no indicadores é alarmante, o que pode ocasionar de certa forma uma perda de informacoes que possam ser
# de grande valia em outras analises. Porem, optou-se nessa situação alheio de mais informações de se remover as variaveis NA's dado o carater
# qualitativo de como as avaliacoes dos indicadores foi inicialmente disposto. Se por ventura fossem notas de variaveis numericas continuas
# poderiamos preenche-las com a media dos dados, porem nao é o caso.



## ANALISE DE CORRELACAO
# filtra apenas variaveis de interesse
selected_columns <- df_alt1[, which(names(df_alt1) == "aval_loc"):which(names(df_alt1) == "efi_img_medic")]


# Calcula a matriz de correlação
correlation_matrix <- cor(selected_columns, use = "complete.obs")

# Plota a matriz de correlação
corrplot(correlation_matrix, method = "color", type = "full", 
         addCoef.col = "black", number.cex = 0.7,
         tl.col = "black", tl.srt = 45, 
         title = "Matriz de Correlação", mar = c(0,0,1,0))


# 1. Satisfação dos Pacientes:
#   
# A variável nvl_satisf tem uma correlação positiva moderada com op_atend (0.37),
# sugerindo que a satisfação dos pacientes está fortemente associada à opinião sobre o atendimento recebido.
# Uma correlação positiva também existe entre nvl_satisf e efi_cuid (0.13),
# indicando que a eficiência dos cuidados também contribui para a satisfação dos pacientes.

# 2. Readmissão e Satisfação:

# nvl_readim tem uma correlação negativa com nvl_satisf (-0.3), indicando que maiores
# taxas de readmissão estão associadas a uma menor satisfação dos pacientes.

# 3. Avaliação Local e Imagem Médica:

# A variável aval_loc tem uma correlação negativa com efi_img_medic (-0.15),
# sugerindo que uma avaliação local mais alta pode estar associada a uma imagem médica menos eficiente.


# 4. Segurança dos Cuidados:

# A variável nvl_seg_cuid mostra uma correlação positiva com efi_cuid (0.14),
# indicando que uma melhor segurança nos cuidados está associada a uma maior eficiência nos cuidados.

# 5. Opinião sobre o Atendimento e Eficiência da Imagem Médica:

# op_atend tem uma correlação negativa com efi_img_medic (-0.2), sugerindo que uma 
# melhor opinião sobre o atendimento pode estar associada a uma eficiência menor na imagem médica.

## ANALISAR ESSES 3 PONTOS PARA AED
# Fatores Positivos para Satisfação: Eficiência dos cuidados e opinião sobre o atendimento são fatores positivos para a satisfação dos pacientes.
# Fatores Negativos para Satisfação: Altas taxas de readmissão e baixa eficiência na imagem médica estão negativamente associadas à satisfação dos pacientes.
# Segurança e Eficiência: Segurança nos cuidados é crucial para a eficiência geral dos cuidados prestados.



# provavelmente vou precisar criar um objeto df_alt2 para utilizar so nessa parte
# Definir a função

# Transformando a coluna "Municipio" em maiúsculas
df_alt1 <- transformar_maiusculas(df_alt1, "cidade")
df_alt1 <- transformar_maiusculas(df_alt1, "estado")

# Calcula a média da avaliação local por estado
media_avaliacoes <- aggregate(aval_loc ~ estado , data = df_alt1, FUN = mean)

# Calcula a média do resultado_geral por estado
media_resultado_geral <- aggregate(resultado_geral ~ estado , data = df_alt1, FUN = mean)

# une as bases
medias <- merge(media_avaliacoes, media_resultado_geral, by = "estado")

# Reshape os dados para formato longo
medias_melted <- melt(medias, id.vars = "estado", variable.name = "metric", value.name = "value")

# Gráfico comparativo entre ambas as metricas
ggplot(medias_melted, aes(x = estado, y = value, color = metric, group = metric)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "Média das Avaliações Locais e Resultados Gerais por Estado",
       x = "Estado",
       y = "Nota",
       color = "Métrica") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# Calcular a correlação de Pearson entre as duas variáveis
correlacao <- cor(medias$aval_loc, medias$resultado_geral, method = "pearson")
# Criar um gráfico de dispersão
ggplot(medias, aes(x = aval_loc, y = resultado_geral)) +
  geom_point() +
  geom_smooth(method = "lm", col = "blue") +
  labs(title = "Dispersão entre Avaliações Locais e Resultados Gerais por Estado",
       x = "Avaliações Locais (aval_loc)",
       y = "Resultados Gerais (resultado_geral)") +
  theme_minimal()
# Exibir a correlação
print(correlacao)



## fim da analise de correlacao

# Agrupa e filtra maior resultado_geral por estado
maiores_resultados <- df_alt1 %>%
  group_by(estado) %>%
  slice_max(order_by = resultado_geral, n = 1)

# Filtra valores NA em resultado_geral
maiores_resultados <- maiores_resultados %>%
  filter(!is.na(resultado_geral))

# Remove duplicados
maiores_resultados <- maiores_resultados %>%
  distinct(estado, .keep_all = TRUE)

# Gráfico de Maiores resultados por estado
ggplot(maiores_resultados, aes(x = reorder(estado, -resultado_geral), y = resultado_geral)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = round(resultado_geral, 2)), vjust = 0.5, hjust = -0.2, size = 4, fontface = "bold") +  # Ajustar posição dos rótulos  theme_minimal() +
  labs(title = "Maior Resultado Geral por Estado",
       x = "Estado",
       y = "Resultado Geral") +  # Legenda
  coord_flip()


## para SAO PAULO
# Agrupa e filtra maior resultado_geral por estado
maiores_resultados_sp <- maiores_resultados %>%
  group_by(estado) %>%
  slice_max(order_by = resultado_geral, n = 10)

maiores_resultados_sp <- maiores_resultados_sp %>% 
  filter(estado == "SP")

# # Gerar o histograma
# ggplot(df_alt1, aes(x = aval_loc, fill = estado)) +
#   geom_histogram(binwidth = 0.5, position = "dodge") +
#   labs(title = "Distribuição das Avaliações por Estado",
#        x = "Avaliação",
#        y = "Contagem") +
#   theme_minimal()


# Distribuição por Estado
hospitais_por_estado <- df_alt1 %>% 
  filter(ctr_PES == "true",
         status == "true",
         serv_emerg == "true") %>%
  group_by(estado) %>%
  summarise(n = n())

# Gráfico de barras por Estado
ggplot(hospitais_por_estado, aes(x = reorder(estado, -n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = n), vjust = -0.3, size = 3.5) +  # Adicionar rótulos de valores
  theme_minimal() +
  labs(title = "Distribuição de Hospitais Ativos por Estado", x = "Estado", y = "Número de Hospitais") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Girar os rótulos dos eixos x

# Distribuição por Município com as 10 maiores contagens
hospitais_por_municipio_top10 <- df_alt1 %>%
  filter(ctr_PES == "true",
         status == "true",
         serv_emerg == "true") %>%
  group_by(cidade) %>%
  summarise(n = n()) %>%
  top_n(10, n) %>%  # Pegando as 10 maiores contagens
  arrange(desc(n))  # Ordenando em ordem decrescente

# Gráfico de barras por Município (os top 10)
ggplot(hospitais_por_municipio_top10, aes(x = reorder(cidade, -n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = n), vjust = -0.3, size = 3.5) +  # Adicionar rótulos de valores
  theme_minimal() +
  labs(title = "Distribuição de Hospitais Ativos por Município (Top 10)", x = "Município", y = "Número de Hospitais") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Girar os rótulos dos eixos x

# Resultado Geral por Estado
resultado_estado <- df_alt1 %>%
  group_by(estado) %>%
  summarise(media_avaliacao = mean(aval_loc, na.rm = TRUE))

# Gráfico de barras do Resultado Geral por Estado
ggplot(resultado_estado, aes(x = reorder(estado, -media_avaliacao), y = media_avaliacao)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = round(media_avaliacao, 2)), vjust = -0.3, size = 3.5) +  # Adicionar rótulos de valores
  theme_minimal() +
  labs(title = "Resultado Geral por Estado", x = "Estado", y = "Média de Avaliação") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Girar os rótulos dos eixos x
## Comparação Antes e Depois para Hospitais

# Convertendo a coluna de data para o formato Date
df_alt$data <- as.Date(df_alt$data)

# Filtrando e comparando antes e depois dos hospitais
## Aqui posso verificar quais hospitais pioraram e melhoraram o resultado (apontando os q melhoraram como possiveis oportunidades)
comparacao <- df_alt %>%
  group_by(id, nm_hosp) %>%
  arrange(id, data) %>%
  summarise(
    primeira_avaliacao = first(resultado_geral),
    ultima_avaliacao = last(resultado_geral)
  ) %>%
  mutate(diferente = primeira_avaliacao != ultima_avaliacao) %>%  # Adiciona coluna indicando se as avaliações são diferentes
  filter(diferente == TRUE)  # Filtra apenas os hospitais onde a avaliação mudou

# Filtrando apenas os hospitais com mais de uma avaliação
comparacao <- comparacao %>%
  filter(!is.na(primeira_avaliacao) & !is.na(ultima_avaliacao))

# Gráfico de comparação
ggplot(comparacao, aes(x = primeira_avaliacao, y = ultima_avaliacao)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Comparação de Avaliações: Antes e Depois", x = "Primeira Avaliação", y = "Última Avaliação")





## avaliar distribuicao de notas para cada criterio de avaliacao (pode usar recorte como estado, cidade, etc)

xtabs(~nvl_mort, df_alt1, addNA = TRUE)


### Outros insights que poderiamos levar




# Calcular a correlação entre aval_loc e resultado_geral
correlacao <- cor(df_alt1$aval_loc, df_alt1$resultado_geral, use = "complete.obs")

# Visualizar o resultado
print(correlacao)

# Correlação positiva de 0.03, ou seja, existe uma possivel relacao entre uma melhor nota da avaliacao local
# influenciar positivamente o resultado geral do hospital. Porém é um efeito muito fraco para ser levado a serio, e lembrando que
# correlacao não necessariamente implica causalidade.

# Acho valido assumir com base nisso que a hipoetese da avaliacao local como ja se tinha conhecimento, ser generica e irrelevante
# , nao refletindo a qualidade dos hospitais de maneira precisa. Poderia servir como um termometro em relacao a como os pacientes
# veem o proprio hospital (testarei com a correlacao)

# Correlacao entre aval_loc e nvl_satisf
correlacao <- cor(df_alt1$aval_loc, df_alt1$nvl_satisf, use = "complete.obs")

# Correlacao negativa de -0.02, ou seja, existe uma possibilidade de influencia quando a nota da avaliacao local aumentar,
# quando a experiencia do paciente tem piores indicadores. Sendo assim, teriamos uma relacao inversa o que nao corrobora com a logica.
# dessa forma, cai por terra a hipotese da avaliacao local ter uma relacao positiva (quando melhor exp do paciente, melhor avaliacao local)
# mas podemos verificar o contrario fazendo a correlacao entre os valores.

# Visualizar o resultado
print(correlacao)


# Criar um gráfico de dispersão com a linha de regressão melhorada
ggplot(df_alt1, aes(x = aval_loc, y = resultado_geral)) +
  geom_point(size = 3, alpha = 0.6, color = "darkred") +
  geom_smooth(method = "lm", col = "blue", linetype = "dashed", size = 1) +
  labs(
    title = "Relação entre Avaliação Local e Resultado Geral",
    subtitle = "Dados de hospitais com avaliação local e resultado geral",
    x = "Avaliação Local",
    y = "Resultado Geral"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12, face = "italic"),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12)
  )
