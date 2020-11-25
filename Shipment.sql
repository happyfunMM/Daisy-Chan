DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_SHIPMENT;
CREATE TABLE userdb_feng_li_4.GC_HC_SHIPMENT
As
(select
ship.day_num,
ship.country,
ship.prod_id,
ship.site_id,
ship.cust_id,
ship.sold_to_cust_id,
ship.mth_num,
ship.category,
--ship.customer,
--ship.channel,
if(ship.customer = 'JINGDONG','JINGDONG',
	if(ecust.eCOMBanner is null,ship.customer,
		IF(ecust.eCOMBanner = 'TMALL FLAGSHIP STORE','Tmall FS',
			IF(ecust.eCOMBanner = 'Tmall Super','Tmall Super',
				IF(ecust.eCOMBanner = 'VIP','VIP',
                                  IF(ecust.eCOMBanner = 'SUNING YIGOU','SUNING YIGOU',
                                   IF(ecust.eCOMBanner = 'Kaola','Kaola',
                                    IF(ecust.eCOMBanner = 'JINGDONG','JINGDONG','Ecom Others')))))))) as customer,
if(ship.channel="JD" or not ecust.eCOMBanner is null,'iOMNI Online',ship.channel) as channel,
ship.shipment_msu,
ship.shipment_cs,
ship.shipment_GIV,
ship.shipment_NIV
FROM
(select
shpmt.day_num,
if(shpmt.geo_id="156","CN",if(shpmt.geo_id="158","TW","HK")) as country,
shpmt.prod_id,
shpmt.site_id,
shpmt.cust_id,
shpmt.sold_to_cust_id,
shpmt.mth_num,
prod.prod_4_name category,
cust.sort_field as customer,
if(substr(cust.group_key,2,1)="6","iOMNI Offline",
	if(substr(cust.group_key,2,1)="1","DMC",
		if(substr(cust.group_key,2,1)="2",'BRAUN',
			if(substr(cust.group_key,2,1)="3",'SCW',
				if(substr(cust.group_key,2,1)="4",'DSC',
					if(substr(cust.group_key,2,1)="7",'iOMNI Online',
						if(substr(cust.group_key,2,1)="8",'RR','Others'))))))) channel,
shpmt.shipment_msu,
shpmt.shipment_cs,
shpmt.GIV_TC shipment_GIV,
shpmt.NIV_TC shipment_NIV
from
(select
	concat_ws('-',substr(cast(fct.day_num as string),1,4),substr(cast(fct.day_num as string),5,2),substr(cast(fct.day_num as string),7,2)) day_num,
	fct.prod_id,
	fct.site_id,
	fct.cust_id,
        fct.sold_to_cust_id,
        fct.geo_id,
	fct.mth_num,
	sum(stat_unit_qty)/1000 shipment_msu,
        sum(case_unit_qty) shipment_cs,
        sum(gross_tc_amt) GIV_TC,
        sum(fct.net_tc_amt) NIV_TC
from    dp_direct_shpmt_cfr.shpmt_fct fct,
	dp_direct_shpmt_cfr.shpmt_class_ind_day_fdim fdim
	where
	fct.shpmt_class_ind_id = fdim.shpmt_class_ind_id 
	and FDIM.CORP_OFFCL_SHIP_FLAG = 'Y'
	and fct.geo_id in ("156","344","446","158")  --filter country
	and fct.FACT_TYPE_CODE in ('BR','BK')  --filter order type
	and fct.PROD_CSU_TYPE_CODE in('S','C')
	---and fdim.job_run_seq_num=(select max(job_run_seq_num) from dp_direct_shpmt_cfr.shpmt_class_ind_day_fdim)
        --and fct.day_num like "201912%"
	--and fct.prod_id="82252925"
group by
	fct.prod_id,
	fct.site_id,
	fct.cust_id,
        fct.sold_to_cust_id,
	fct.mth_num,
        fct.geo_id,
	concat_ws('-',substr(cast(fct.day_num as string),1,4),substr(cast(fct.day_num as string),5,2),substr(cast(fct.day_num as string),7,2))) shpmt,
dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod,
dp_masterdata_g11.ztxxptmelf_fpc_external_life_cycle seg,
dp_osi_ap_ecc.kna1_general_data_in_customer_master cust
WHERE
shpmt.prod_id=prod.prod_id
and shpmt.prod_id=substr(seg.id_of_product_material,11,8)
and seg.life_cycle_scope =if(shpmt.geo_id="156","CN",if(shpmt.geo_id="158","TW","HK"))
and shpmt.cust_id=cust.customer_number
and UPPER(prod.prod_4_name)LIKE "%HAIR%") ship

left join userdb_feng_li_4.uploaded_ecom_shipto_list ecust 
on ship.cust_id=ecust.`Ship-to Code`)