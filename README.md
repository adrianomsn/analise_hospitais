# Análise de Oportunidade em Saúde: Melhores Hospitais para Integração

## Introdução

Este projeto visa atender à necessidade de uma empresa de saúde em tecnologia que avalia hospitais para parcerias de trabalho. Para isso, utilizamos uma base de dados com critérios de avaliação de instituições hospitalares.

O objetivo principal é analisar e identificar os hospitais mais adequados nas 3 cidades com maior atividade no setor hospitalar. A seleção inicial foca em critérios de prestação de serviços e assistência hospitalar, priorizando os 3 hospitais com o melhor "Resultado Geral" em cada cidade.

Em seguida, definimos a ordem de prioridade para a integração, considerando a localização da empresa e o tempo/distância de deslocamento até o hospital. Além disso, o projeto busca identificar futuras oportunidades em outras localidades e instituições com qualidade em gestão hospitalar.

---

## Metodologia

A análise iniciou com o tratamento e filtro da base de dados, aplicando os seguintes critérios mínimos para selecionar hospitais elegíveis:

* Considerar apenas a data de competência mais atual para avaliar o status recente do hospital.
* Considerar apenas hospitais ativos.
* O hospital deve atender aos critérios para o uso do Prontuário Eletrônico de Saúde.
* O hospital precisa prestar serviços de emergência.

Após a aplicação desses filtros, foram selecionados os 3 municípios com a maior quantidade de hospitais ativos que atendiam aos requisitos mínimos.

A metodologia de cálculo do indicador de "resultado_geral" considerou uma média ponderada dos escores hospitalares. Os pesos foram definidos com base em uma consulta a profissionais da área da saúde e artigos da OMS e afins sobre gestão hospitalar, seguindo a seguinte ordem de prioridade e peso:

1.  Segurança da informação (Peso: 3)
2.  Mortalidade no hospital (Peso: 2.5)
3.  Utilização eficiente de imagens médicas (Peso: 2.25)
4.  Experiência do paciente (Peso: 1.75)
5.  Cuidados com o paciente (Peso: 1.50)
6.  Oportunidade de atendimento (Peso: 1.35)
7.  Readmissão hospitalar (Peso: 1.15)

A fórmula utilizada para calcular o resultado geral foi a seguinte média ponderada:

![lagrida_latex_editor (2)](https://github.com/user-attachments/assets/08845570-d379-4266-90a1-61624461d1fb)

Onde:
* `nvl_seg_cuid`: Escore de Segurança e Cuidados.
* `nvl_mort`: Escore de Mortalidade.
* `efi_img_medic`: Escore de Eficiência em Imagens Médicas.
* `nvl_satisf`: Escore de Satisfação do Paciente.
* `efi_cuid`: Escore de Eficiência de Cuidados.
* `op_atend`: Escore de Oportunidade de Atendimento.
* `nvl_readim`: Escore de Nível de Readmissão.
* $13.5$ é a soma total dos pesos.

Para o cálculo da distância e tempo de deslocamento entre a localização da empresa e os hospitais, foram consideradas duas velocidades médias:

* Velocidade média de deslocamento por carro: 80 km/h.
* Velocidade média de voo: 600 km/h (utilizada para casos de maiores distâncias).

O tempo de deslocamento foi calculado utilizando a fórmula básica de tempo, sendo apresentado em horas e minutos.  
![lagrida_latex_editor (3)](https://github.com/user-attachments/assets/ef051b83-9bb3-4c03-8281-cff3cade0927)

---

Os resultados da análise do Indicador Geral de Gestão Hospitalar apresenta uma avaliação nos níveis Nacional, Estadual e Municipal, com o objetivo de identificar os melhores hospitais para integração.

A seleção inicial dos hospitais baseou-se nos maiores valores do 'resultado_geral', que representa a média ponderada dos escores hospitalares. O critério de avaliação subsequente para definir a ordem de integração, conforme as instruções do projeto, foi o tempo e a distância de deslocamento.

## Resultado Final: Hospitais Selecionados por Cidade e Ordem de Integração


### São Paulo

| Ordem | Nome do Hospital          | ID    | Nota Geral | Distância | Tempo de Deslocamento |
| :---- | :------------------------ | :---- | :--------- | :-------- | :-------------------- |
| 1º    | Hospital do Coração       | 70013 | 3.0        | 599m      | Menos de 1 minuto     |
| 2º    | Hospital Sírio Libanês    | 70024 | 2.49       | 1,46 km   | 1 a 2 minutos         |
| 3º    | Hospital Central de Guaianazes | 70523 | 2.51       | 25,4 km   | 20 minutos            |

### Rio de Janeiro

| Ordem | Nome do Hospital            | ID    | Nota Geral | Distância | Tempo de Deslocamento |
| :---- | :-------------------------- | :---- | :--------- | :-------- | :-------------------- |
| 1º    | Hospital Norte Dor          | 70066 | 2.381481   | 348.1 km  | 04h 21m               |
| 2º    | Clínica Traumato Ortopédica | 70443 | 2.374074   | 347.1 km  | 04h 20m               |
| 3º    | Hospital Mario Kroeff       | 70453 | 2.366667   | 353.6 km  | 04h 25m               |

### Salvador

| Ordem | Nome do Hospital          | ID    | Nota Geral | Distância | Tempo de Deslocamento |
| :---- | :------------------------ | :---- | :--------- | :-------- | :-------------------- |
| 1º    | Cardio Pulmonar da Bahia  | 70769 | 2.422      | 1451.4 km | 18h 09 minutos        |
| 2º    | Hospital Santo Amaro      | 70789 | 2.222222   | 1451.2 km | 18h 08 minutos        |
| 3º    | Hospital da Cidade        | 70784 | 2.222222   | 1456,2 km | 18h 12 minutos        |

## Resultado Final: Hospitais para Integração Prioritária

O resultado final apresenta o principal hospital de cada cidade com o melhor resultado geral, priorizando a ordem de integração com base na nota geral, distância e tempo de deslocamento.

1.  **Hospital do Coração** (São Paulo - SP)
    * **Justificativa:** Apresentou a melhor nota no resultado geral e a menor distância e tempo de deslocamento entre os hospitais analisados em São Paulo. Assumindo uma velocidade de locomoção de 80 km/h, o tempo estimado é de 1 minuto.

2.  **Hospital Norte Dor** (Rio de Janeiro - RJ)
    * **Justificativa:** Destacou-se com a melhor nota no resultado geral e a menor distância e tempo de deslocamento entre os hospitais analisados no Rio de Janeiro. Assumindo uma velocidade de locomoção de 80 km/h, o tempo estimado é de 4 horas e 21 minutos. Se considerado deslocamento aéreo, o tempo reduz para pouco mais de 1 hora.

3.  **Cardio Pulmonar da Bahia** (Salvador - BA)
    * **Justificativa:** Obteve a melhor nota no resultado geral e a menor distância e tempo de deslocamento entre os hospitais analisados em Salvador. Assumindo uma velocidade de locomoção de 80 km/h, o tempo estimado é de 18 horas e 09 minutos. Se considerado deslocamento aéreo, o tempo reduz para pouco mais de 2 horas e 20 minutos.

## Insights Adicionais e Oportunidades Futuras

Os hospitais remanescentes da lista tríplice de cada cidade também apresentaram bons resultados e representam futuras oportunidades de integração para a empresa. O ótimo nível demonstrado na avaliação, tanto pelos serviços e práticas quanto pelo baixo tempo de deslocamento em relação à localização da empresa, reforça seu potencial.

Todos os hospitais selecionados, tanto na lista principal quanto na lista de sugestões adicionais, são hospitais de cuidados agudos. Isso implica que são maiores, oferecem mais serviços médicos, especialidades e possuem maior infraestrutura. Essa característica pode ser um ponto focal para futuras integrações, dada a maior cobertura de atendimento, ampla variedade de serviços, vínculos com seguradoras privadas ou programas governamentais, e estrutura com funcionalidade 24 horas por dia, 7 dias por semana. Parcerias com instituições de maior estrutura, qualidade e capilaridade tendem a resultar em maiores benefícios financeiros para a empresa.

### Ordem de Prioridade para os Demais Hospitais Ranqueados:

| Ordem | Nome do Hospital            | Local            | Resultado Geral | Distância | Tempo de Deslocamento |
| :---- | :-------------------------- | :--------------- | :-------------- | :-------- | :-------------------- |
| 1º    | Hospital Paulistano         | São Paulo - SP   | 2.422222        | 800m      | 1 minuto              |
| 2º    | Hospital Albert Sabin       | São Paulo - SP   | 2.418519        | 8,5 km    | 6 minutos             |
| 3º    | Hospital Sagrada Família    | São Paulo - SP   | 2.388889        | 11 km     | 8 minutos             |
| 4º    | Hospital Samaritano Barra   | Rio de Janeiro - RJ | 2.351852        | 341,4 km  | 04h 16 min            |
| 5º    | Hospital de Clínicas Santa Cruz | Rio de Janeiro - RJ | 2.351852        | 312 km    | 3h 54 minutos         |
| 6º    | Ordem Terceira do Carmo     | Rio de Janeiro - RJ | 2.318519        | 362 km    | 4h 32 minutos         |
| 7º    | Hospital Aliança            | Salvador - BA    | 2.148148        | 1452.1 km | 18h 09 minutos        |
| 8º    | Oftalmoclin               | Salvador - BA    | 2.151852        | 1452.3 km | 18h 09 minutos        |
| 9º    | CTO Médico Agenor Paiva     | Salvador - BA    | 2.177778        | 1458.07 km| 18h 14 minutos        |


