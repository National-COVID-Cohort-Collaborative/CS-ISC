

@transform_pandas(
    Output(rid="ri.vector.main.execute.99c7aa9e-ce28-4ca8-ac6e-b61bc8d073a0"),
    ACS_2018_Households_and_Families_Data_by_ZCTA5_raw_=Input(rid="ri.foundry.main.dataset.0c617223-5b25-4f4c-af72-7e0815550cc5")
)
-- ACS_family_size (0f4ebdb1-655a-4c2f-be05-4883968c8b25): v0
SELECT split(id, "US")[1] as ZIP, EstimateTotalHOUSEHOLDSAverage_household_size as avg_household_size, Margin_of_ErrorTotal_MOEHOUSEHOLDSAverage_household_size as error_avg_household_size, EstimateTotalHOUSEHOLDSTotal_households as total_households
FROM ACS_2018_Households_and_Families_Data_by_ZCTA5_raw_

@transform_pandas(
    Output(rid="ri.vector.main.execute.d4a8d506-2dee-49b7-93a4-19753544e91d"),
    ACS_house_family=Input(rid="ri.vector.main.execute.99c7aa9e-ce28-4ca8-ac6e-b61bc8d073a0"),
    avg_ADI=Input(rid="ri.vector.main.execute.90e35428-d557-4092-a1f3-3bbf34aa5ac0"),
    county_to_zip2=Input(rid="ri.vector.main.execute.613a6b94-1d6d-471e-a4f0-0c74c1babe30")
)
-- transform_adi_to_county (131f6260-138f-466c-beb6-79cd77a499e4): v0
select Preferred_county as fips_code, round(people/total_hh, 2) as avg_household_size, round(adi_pop/total_pop,2) as ADI
from 
(select distinct Preferred_county,  sum(avg_household_size*total_households) as people, sum(total_households) as total_hh, sum(ADI*zip_pop) as adi_pop, sum(zip_pop) as total_pop
    from 
    county_to_zip2  
    LEFT JOIN ACS_house_family using (ZIP)
    LEFT JOIN avg_ADI using(ZIP) 

    group by Preferred_county) bar

@transform_pandas(
    Output(rid="ri.vector.main.execute.90e35428-d557-4092-a1f3-3bbf34aa5ac0"),
    US_ADI_by_ZCTA_2020_Broadstreet_=Input(rid="ri.foundry.main.dataset.cae95b88-f359-4921-b21a-67ce0ca130b4"),
    zip_pop=Input(rid="ri.vector.main.execute.eb624a5e-bb45-4216-bc2e-238b1d4aa2a5")
)
-- extract_zip_ADI_file (e81b4d87-9495-4082-a220-f2fc2d215a01): v0
select foo.ZIP, ADI, zip_pop from 
(SELECT  split(Geographic_Identifier, "US")[1] as ZIP, Area_Deprivation_Index_ as ADI
FROM US_ADI_by_ZCTA_2020_Broadstreet_) foo
inner join zip_pop on (foo.ZIP=zip_pop.ZIP)

@transform_pandas(
    Output(rid="ri.vector.main.execute.613a6b94-1d6d-471e-a4f0-0c74c1babe30"),
    ZIP_COUNTY_HUD_file=Input(rid="ri.foundry.main.dataset.9ac4d85e-8d54-45b0-ab0c-da4180067c3e")
)
-- county_to_zip (2be95542-e3b2-4de3-82e1-726c7389886e): v0
SELECT distinct ZIP, Preferred_county
FROM ZIP_COUNTY_HUD_file

@transform_pandas(
    Output(rid="ri.vector.main.execute.8f30348d-42c5-4cfb-a365-99af84dbaa3a"),
    ACS_house_family_final=Input(rid="ri.vector.main.execute.d4a8d506-2dee-49b7-93a4-19753544e91d"),
    County_Level_SDI_2015_=Input(rid="ri.foundry.main.dataset.f24dccf0-38f6-4877-909c-49727b4d52f6"),
    food_access_transform=Input(rid="ri.vector.main.execute.041ef5f6-9fa7-41df-a4da-0cbe0c7663f1"),
    us_adm2_sci_county_benchmark=Input(rid="ri.foundry.main.dataset.e1c080c5-9ead-4ca7-b1fd-a62540555a0f")
)
-- sdoh_county (8c3c101a-5b25-46eb-af99-66c4df66c2c6): v0
SELECT a.fips_code,avg_household_size, sdi_score,unemployment_rate,poverty_rate,children_in_family_receiving_public_assistance_snap_ssi as snap_rate,without_health_insurance,who_smoke,mean_commute_time,density, rural,black,hispanic, sci.foreign_born, `black-white_segregation` as black_white_segregation,low_food_access_perc, ADI
FROM ACS_house_family_final a
left join  County_Level_SDI_2015_ s on (a.fips_code=s.county)
left join us_adm2_sci_county_benchmark sci on (sci.fips_code=a.fips_code)
left join food_access_transform fat on (sci.fips_code=fat.fips_code)

@transform_pandas(
    Output(rid="ri.vector.main.execute.d9cf09dd-1a80-4bdb-8f50-49acc8edbd04"),
    ZIP_COUNTY_HUD_file=Input(rid="ri.foundry.main.dataset.9ac4d85e-8d54-45b0-ab0c-da4180067c3e"),
    final_sdohstatic=Input(rid="ri.vector.main.execute.8f30348d-42c5-4cfb-a365-99af84dbaa3a")
)
SELECT distinct final_sdohstatic.*, ZIP, Preferred_county
FROM final_sdohstatic
inner join ZIP_COUNTY_HUD_file on (fips_code=Preferred_county)

@transform_pandas(
    Output(rid="ri.vector.main.execute.041ef5f6-9fa7-41df-a4da-0cbe0c7663f1"),
    DataDownload_2015_Food_Access_Research_Atlas=Input(rid="ri.foundry.main.dataset.fcd07b5b-cf6c-423f-b960-a4c95084b7cc")
)
-- food_access_transform (29aa59ee-f1ae-47b7-adf8-e4e689266140): v0
select fips_code, LAPOP1_10/POP2010 as low_food_access_perc
from
(SELECT CountyCode as fips_code, sum(LAPOP1_10) as LAPOP1_10, sum(POP2010) as POP2010
FROM DataDownload_2015_Food_Access_Research_Atlas
group by CountyCode) foo

@transform_pandas(
    Output(rid="ri.vector.main.execute.eb624a5e-bb45-4216-bc2e-238b1d4aa2a5"),
    ACS_2018_Population_by_ZCTA5_raw_=Input(rid="ri.foundry.main.dataset.255ae558-8b89-4c9c-92dd-c277400f67ce")
)
-- zip_population (71bec984-8e5f-43a0-8603-d5ac9f5a6fb6): v0
SELECT split(id, "US")[1] as ZIP, EstimateTotal as zip_pop
FROM ACS_2018_Population_by_ZCTA5_raw_

