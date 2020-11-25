DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_Service;
CREATE TABLE userdb_feng_li_4.GC_HC_Service As(
  SELECT
    ship.day_num,
    ship.mth_num,
    ship.country,
    ship.prod_id,
    ship.Production_plant,
    ship.DC,
    ship.cust_id,
    ship.Desc,
    ship.brand,
    ship.sub_brand,
    ship.Category,
    if(
      ship.customer = 'JINGDONG',
      'JINGDONG',
      if(
        ecust.eCOMBanner is null,
        ship.customer,
        IF(
          ecust.eCOMBanner = 'TMALL FLAGSHIP STORE',
          'Tmall FS',
          IF(
            ecust.eCOMBanner = 'Tmall Super',
            'Tmall Super',
            IF(
              ecust.eCOMBanner = 'VIP',
              'VIP',
              IF(
                ecust.eCOMBanner = 'SUNING YIGOU',
                'SUNING YIGOU',
                IF(
                  ecust.eCOMBanner = 'Kaola',
                  'Kaola',
                  IF(
                    ecust.eCOMBanner = 'JINGDONG',
                    'JINGDONG',
                    'Ecom Others'
                  )
                )
              )
            )
          )
        )
      )
    ) as customer,
    if(
      ship.channel = "JD"
      or not ecust.eCOMBanner is null,
      'iOMNI Online',
      ship.channel
    ) as channel,
    ship.SU_Shipment,
    ship.giv_tc,
    ship.niv_tc,
    ship.Total_Cut,
    ship.CFR_Cut
  FROM
    (
      SELECT
        cfr.day_num,
        cfr.mth_num,
        if(geo_id = "156", "CN", if(geo_id = "158", "TW", "HK")) as country,
        cfr.prod_id,
        cfr.plant_id as Production_plant,
        cfr.site_id as DC,
        cfr.cust_id,
        prod.name as Desc,
        idp.product_brand_name as brand,
        IF(
          idp.product_brand_name = "REJOICE",
          IF(idp.attribute2 = "DAILYCARE", "RJC FC", "RJC EC"),
          product_brand_name
        ) AS sub_brand,
        prod.prod_4_name as Category,
        cust.sort_field as customer,
        if(
          substr(cust.group_key, 2, 1) = "6",
          "iOMNI Offline",
          if(
            substr(cust.group_key, 2, 1) = "1",
            "DMC",
            if(
              substr(cust.group_key, 2, 1) = "2",
              'BRAUN',
              if(
                substr(cust.group_key, 2, 1) = "3",
                'SCW',
                if(
                  substr(cust.group_key, 2, 1) = "4",
                  'DSC',
                  if(
                    substr(cust.group_key, 2, 1) = "7",
                    'iOMNI Online',
                    if(substr(cust.group_key, 2, 1) = "8", 'RR', 'Others')
                  )
                )
              )
            )
          )
        ) as channel,
        sum(cfr.SU_Shipment) as SU_Shipment,
        sum(cfr.giv_tc) as giv_tc,
        sum(cfr.niv_tc) as niv_tc,
        sum(cfr.Total_Cut) as Total_Cut,
        sum(cfr.CFR_Cut) as CFR_Cut
      FROM
        (
          SELECT
            IFNULL(shpmt.day_num, cut.day_num) as day_num,
            IFNULL(shpmt.mth_num, cut.mth_num) as mth_num,
            IFNULL(shpmt.geo_id, cut.geo_id) as geo_id,
            IFNULL(shpmt.prod_id, cut.prod_id) as prod_id,
            IFNULL(shpmt.cust_id, cut.cust_id) as cust_id,
            IFNULL(shpmt.plant_id, cut.plant_id) as plant_id,
            IFNULL(shpmt.site_id, cut.site_id) as site_id,
            shpmt.SU_Shipment,
            shpmt.giv_tc,
            shpmt.niv_tc,
            cut.Total_Cut,
            cut.CFR_Cut
          FROM
            (
              Select
                su.day_num,
                su.mth_num,
                su.geo_id,
                su.cust_id,
                su.plant_id,
                su.site_id,
                su.prod_id,
                sum(su.su_shipment) as su_shipment,
                sum(giv.giv_tc) as giv_tc,
                sum(giv.niv_tc) as niv_tc --sum(giv.su_shipment) as giv_su_shipment
              from
                (--
                  SELECT
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.plant_id,
                    fct.site_id,
                    fct.prod_id,
                    fct.orig_tranx_id,
                    sum(stat_unit_qty) su_shipment
                  FROM
                    dp_direct_shpmt_cfr.shpmt_cfr_sh_fct fct,
                    dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod
                  WHERE
                    fct.prod_id = prod.prod_id
                    and fct.geo_id in ("156", "344", "446", "158")
                    and fct.srce_sys_id in (3490, 2973, 858, 861)
                    and UPPER(prod.prod_4_name) LIKE "%HAIR%" --and fct.mth_num
                  group by
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.plant_id,
                    fct.site_id,
                    fct.prod_id,
                    fct.orig_tranx_id
                ) su
                left join (
                  select
                    fct.orig_tranx_id,
                    sum(fct.stat_unit_qty) su_shipment,
                    sum(fct.gross_tc_amt) GIV_TC,
                    sum(fct.net_tc_amt) NIV_TC
                  from
                    dp_direct_shpmt_cfr.shpmt_fct fct,
                    dp_direct_shpmt_cfr.shpmt_class_ind_day_fdim fdim
                  where
                    fct.shpmt_class_ind_id = fdim.shpmt_class_ind_id
                    and FDIM.CORP_OFFCL_SHIP_FLAG = 'Y'
                    and fct.geo_id in ("156", "344", "446", "158")
                    and fct.FACT_TYPE_CODE in ('BR', 'BK')
                    and fct.PROD_CSU_TYPE_CODE in('S', 'C')
                    and fct.srce_sys_id in (3490, 2973, 858, 861)
                    and fct.gross_tc_amt <> 0 --and fct.mth_num
                  group by
                    fct.orig_tranx_id
                ) giv on su.orig_tranx_id = giv.orig_tranx_id
              group by
                su.day_num,
                su.mth_num,
                su.geo_id,
                su.cust_id,
                su.plant_id,
                su.site_id,
                su.prod_id
            ) shpmt FULL
            JOIN (
              SELECT
                totalcut.day_num,
                totalcut.mth_num,
                totalcut.geo_id,
                totalcut.plant_id,
                totalcut.site_id,
                totalcut.cust_id,
                totalcut.prod_id,
                totalcut.Total_Cut,
                cfrcut.CFR_Cut
              FROM
                (
                  select
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.prod_id,
                    fct.plant_id,
                    fct.site_id,
                    --fct.reasn_code_id,
                    --prod.prod_4_name,
                    sum(stat_unit_qty) Total_Cut
                  from
                    dp_direct_shpmt_cfr.shpmt_cfr_mc_fct fct,
                    dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod
                  where
                    fct.prod_id = prod.prod_id
                    and fct.geo_id in ("156", "900", "344", "446", "158")
                    and fct.srce_sys_id in (3490, 2973, 858, 861)
                    AND fct.reasn_code_id IN (
                      'AS_01',
                      'AS_02',
                      'AS_07',
                      'AS_08',
                      'AS_12',
                      'GC_01',
                      'GC_02',
                      'GC_05',
                      'GC_07',
                      'GC_08',
                      'GC_09',
                      'GC_10',
                      'GC_12',
                      'GC_35',
                      'GC_48',
                      'GC_49',
                      'GC_50',
                      'GC_51',
                      'GC_58',
                      'GC_59',
                      'GC_62',
                      'GC_82',
                      'GC_92'
                    ) --and fct.mth_num
                    and UPPER(prod.prod_4_name) LIKE "%HAIR%"
                  group by
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.plant_id,
                    fct.site_id,
                    fct.prod_id
                ) totalcut
                LEFT JOIN (
                  select
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.prod_id,
                    fct.plant_id,
                    fct.site_id,
                    --fct.reasn_code_id,
                    --prod.prod_4_name,
                    sum(stat_unit_qty) CFR_Cut
                  from
                    dp_direct_shpmt_cfr.shpmt_cfr_mc_fct fct,
                    --dp_direct_shpmt_cfr.shpmt_root_cause_178_day_fdim rca,
                    dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod
                  where
                    --fct.root_caus_id=rca.root_caus_id
                    fct.prod_id = prod.prod_id
                    and fct.geo_id in ("156", "900", "344", "446", "158")
                    and fct.srce_sys_id in (3490, 2973, 858, 861)
                    AND fct.reasn_code_id IN ('GC_07') --and fct.mth_num >= '201801'
                    and Not(
                      fct.root_caus_id in (
                        '103380',
                        '103381',
                        '103392',
                        '103393',
                        'UNKN',
                        '103394',
                        '103395',
                        '103396',
                        '103397',
                        '103398',
                        '103399',
                        '103400',
                        '103401',
                        '103402',
                        '103403',
                        '103404',
                        '103405',
                        '103406',
                        '103407',
                        '103408',
                        '103409',
                        '103410',
                        '103411',
                        '103412',
                        '103413',
                        '103414',
                        '103415',
                        '103416',
                        '103417',
                        '103418',
                        '103419',
                        '103420',
                        '103421'
                      )
                    )
                    and UPPER(prod.prod_4_name) LIKE "%HAIR%"
                  group by
                    fct.day_num,
                    fct.mth_num,
                    fct.geo_id,
                    fct.cust_id,
                    fct.plant_id,
                    fct.site_id,
                    fct.prod_id
                ) cfrcut on totalcut.cust_id = cfrcut.cust_id
                and totalcut.geo_id = cfrcut.geo_id
                and totalcut.prod_id = cfrcut.prod_id
                and totalcut.day_num = cfrcut.day_num
                and totalcut.plant_id = cfrcut.plant_id
                and totalcut.site_id = cfrcut.site_id
            ) cut ON shpmt.day_num = cut.day_num
            and shpmt.prod_id = cut.prod_id
            and shpmt.cust_id = cut.cust_id
            and shpmt.plant_id = cut.plant_id
            and shpmt.site_id = cut.site_id
        ) cfr,
        dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod,
        dp_osi_ap_ecc.kna1_general_data_in_customer_master cust
        left join dp_demand_forecast_idp.asia_product_dim idp on cfr.prod_id = substr(idp.product_id, 11, 8)
      WHERE
        cfr.prod_id = prod.prod_id
        and cfr.cust_id = cust.customer_number --and prod.prod_4_name="Oral Care"
      group by
        cfr.day_num,
        cfr.mth_num,
        if(geo_id = "156", "CN", if(geo_id = "158", "TW", "HK")),
        cfr.prod_id,
        cfr.plant_id,
        cfr.site_id,
        prod.name,
        prod.prod_4_name,
        cfr.cust_id,
        if(
          substr(cust.group_key, 2, 1) = "6",
          "iOMNI Offline",
          if(
            substr(cust.group_key, 2, 1) = "1",
            "DMC",
            if(
              substr(cust.group_key, 2, 1) = "2",
              'BRAUN',
              if(
                substr(cust.group_key, 2, 1) = "3",
                'SCW',
                if(
                  substr(cust.group_key, 2, 1) = "4",
                  'DSC',
                  if(
                    substr(cust.group_key, 2, 1) = "7",
                    'iOMNI Online',
                    if(substr(cust.group_key, 2, 1) = "8", 'RR', 'Others')
                  )
                )
              )
            )
          )
        ),
        cust.sort_field,
        idp.product_brand_name,
        IF(
          idp.product_brand_name = "REJOICE",
          IF(idp.attribute2 = "DAILYCARE", "RJC FC", "RJC EC"),
          product_brand_name
        )
    ) ship
    left join userdb_feng_li_4.uploaded_ecom_shipto_list ecust on ship.cust_id = ecust.`Ship-to Code`
)