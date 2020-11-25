DROP TABLE IF EXISTS userdb_feng_li_4.gc_hc_daily_inventory;
CREATE TABLE userdb_feng_li_4.gc_hc_daily_inventory
As(
select inventory.*,
monthlyforecast.forecast
from

	(select to_date(concat(substr(Inv.cal_day,1,4),"-",substr(Inv.cal_day,5,2),"-",substr(Inv.cal_day,7,2)))as Date,
	Inv.plant_cntry_code as Country,
	Inv.prod_type_code as Material_Type,
	Inv.plant_id as Plant,
	plantname.city as Plant_Description,
	plantname.name as Plant_Detailed_Description,
	Inv.suppl_netwk_prod_plant_id as SNP_Plant,
	plantname1.city as SNP_Plant_Description,
	plantname1.name as SNP_Plant_Detailed_Description,
	substr(Inv.prod_id,11,8) as MaterialCode,
	Des.name_short_description_of_product as Material_Description,
	Des.market_segmentation as Segmentation,
	Inv.tdc_val_subsector_name as Subsector,
	Inv.tdc_val_category_code as Category,
	materialmaster.safety_time_duration_day_cnt as Safety_Time,
	materialmaster.safety_stock_qty as Safety_Stock,
	sum(Inv.tot_plant_stock_buom_qty)  as BUoM_Total_Plant_Stock,
	sum(Inv.tot_plant_stock_msu_val)/1000 as MSU_Total_Plant_Stock,
	sum(Inv.tot_plant_stock_usd_amt) as USD_Total_Plant_Stock,
	sum(Inv.stock_in_trnst_buom_qty) as BUoM_In_Transit,
	sum(Inv.stock_in_trnst_msu_val)/1000 as MSU_In_Transit,
	sum(Inv.stock_in_trnst_usd_amt) as USD_In_Transit,
	sum(Inv.blocked_buom_qty) as BUoM_Blocked,
	sum(Inv.blocked_msu_val)/1000 as MSU_Blocked,
	sum(Inv.blocked_usd_amt) as USD_Blocked,
	sum(Inv.max_stock_buom_qty) as BUoM_Max_Stock,
	sum(Inv.max_stock_msu_val)/1000 as MSU_Max_Stock,
	sum(Inv.max_stock_usd_amt) as USD_Max_Stock,
	sum(Inv.sfty_stock_buom_qty) as BUoM_Safety_Stock,
	sum(Inv.sfty_stock_msu_val)/1000 as MSU_Safety_Stock,
	sum(Inv.sfty_stock_usd_amt) as USD_Safety_Stock,
	sum(Inv.mrp_avail_csp_buom_qty) as BUoM_MRP_Available,
	sum(Inv.mrp_avail_csp_msu_val)/1000 as MSU_MRP_Available,
	sum(Inv.mrp_avail_csp_usd_amt) as USD_MRP_Available

	from dp_osi_bw_global.inventory_part_final_pq as Inv


left join 

	(select 
	substr(Mat.id_of_product_material,11,8) material_number,
	Mat.name_short_description_of_product,
	SPACED.market_segmentation
	from dp_osi_ap_ecc.makt_material_descriptions as Mat 

	left join
		(select
		substr(g11.id_of_product_material,11,8) material_number,
		g11.market_segmentation
		 from
		dp_masterdata_g11.ztxxptmelf_fpc_external_life_cycle as g11
		 where g11.life_cycle_scope = "CN") as SPACED 
	on substr(mat.id_of_product_material,11,8) = SPACED.material_number
	where Mat.language_code="E") as Des
	
on Des.material_number=substr(Inv.prod_id,11,8)

left join 
	(select plant.site_plant_code as plant, plant.city, plant.name_1 as name, plant.country_key from dp_osi_ap_ecc.t001w_plants_branches as plant) as plantname 
on Inv.plant_id=plantname.plant
--plant_id和suppl_netwk_prod_plant_id有什么区别吗?
left join 
	(select plant1.site_plant_code as plant, plant1.city, plant1.name_1 as name from dp_osi_ap_ecc.t001w_plants_branches as plant1) as plantname1 
on Inv.suppl_netwk_prod_plant_id=plantname1.plant

left join
	(select marc.prod_id,marc.plant_id,marc.safety_time_duration_day_cnt, marc.safety_stock_qty from dp_osi_ap_ecc.prod_plant_lkp as marc) as materialmaster
on Inv.prod_id=materialmaster.prod_id and Inv.plant_id=materialmaster.plant_id


where
Inv.cal_day>=20170701
and Inv.geo_grp_name="GREATER CHINA GROUP"
and UPPER(Inv.tdc_val_subsector_name) LIKE "%HAIR%"
--and Inv.tdc_val_category_code="HAIRCARE"
and Inv.prod_decomp_code <> "L"
and not (Inv.tot_plant_stock_usd_amt=0 and Inv.sfty_stock_usd_amt=0 and Inv.mrp_avail_csp_usd_amt=0)

group by Inv.prod_id, 
Inv.plant_id,
to_date(concat(substr(Inv.cal_day,1,4),"-",substr(Inv.cal_day,5,2),"-",substr(Inv.cal_day,7,2))),
Inv.plant_cntry_code,
Inv.prod_type_code,
Inv.suppl_netwk_prod_plant_id,
Inv.tdc_val_subsector_name,
Inv.tdc_val_category_code,
Des.name_short_description_of_product,
Inv.tot_plant_stock_usd_amt,
Inv.max_stock_usd_amt,
Inv.sfty_stock_usd_amt,
Des.market_segmentation,
plantname.city,
plantname.name,
plantname1.city,
plantname1.name,
materialmaster.safety_stock_qty,
materialmaster.safety_time_duration_day_cnt) as inventory

left join
	 (select
	 demand.frcst_genertn_date,
	substr(demand.product_id,11,8) as SKU,
	demand.loc_id,
	sum(demand.shpmt_frcst_qty)/1000 as forecast
	from
	 dp_demand_forecast_idp.asia_frcst_hist_weekly_fct as demand
	where demand.region_code="AP"
	and demand.channel_id in ("CN_C","CN_R","TW_R")
	and datediff(demand.frcst_valid_date,demand.frcst_genertn_date)<=28
	and demand.frcst_genertn_date=
		(select max(frcst_genertn_date)
		from dp_demand_forecast_idp.asia_frcst_hist_weekly_fct
		where region_code="AP"
		and channel_id in ("CN_C","CN_R","TW_R"))
		group by demand.product_id, demand.loc_id,demand.frcst_genertn_date) as monthlyforecast
		on inventory.MaterialCode=monthlyforecast.SKU and inventory.plant=monthlyforecast.loc_id)