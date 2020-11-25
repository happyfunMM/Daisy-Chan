DROP TABLE IF EXISTS userdb_feng_li_4.gc_hc_production;
CREATE TABLE userdb_feng_li_4.gc_hc_production As(
  SELECT
    substr(production.order_num, 4, 9) order_num,
	--plant_id
    production.plan_plant_id,
	--生产线id?
    production.repettv_manfctr_prodn_line_code,
	--prod version id?
    production.prodn_version_id,
	-- sku id
    substr(production.prod_id, 11, 8) prod_id,
	--sku name
    production.prod_name,
    production.batch_id,
    production.schedule_start_date,
	--?
    production.basic_start_time_val,
    production.schedule_finish_date,
    production.basic_finish_time_val,
    production.base_qty,
    production.total_plan_order_qty,
	-- gr?
    production.gr_qty,
    production.order_cnfrmtn_yield_confirm_qty,
    production.base_uom,
    production.confirm_order_finish_date,
    prod.prod_3_name as Category,
    prod.prod_4_name as Sub_Category,
    if(
      idp.product_brand_name IS NOT NULL,
      idp.product_brand_name,
      if(
        (
          production.prod_name LIKE "%HS %"
          OR production.prod_name LIKE "%HS %"
          OR production.prod_name LIKE "%H&S%"
        ),
        "HD&SHLDRS",
        if(
          (
            production.prod_name LIKE "%PTN %"
            OR production.prod_name LIKE "%PNT %"
            OR production.prod_name LIKE "%PANTENE%"
          ),
          "PANTENE",
          if(
            (
              production.prod_name LIKE "%RJC %"
              OR production.prod_name LIKE "%REJ %"
              OR production.prod_name LIKE "%Rejoice%"
            ),
            "REJOICE",
            if(
              (
                production.prod_name LIKE "%VS %"
                OR production.prod_name LIKE "%VIDALSASON%"
              ),
              "VIDALSASON",
              if(
                (
                  production.prod_name LIKE "%AUSSIE%"
                  OR production.prod_name LIKE "%AU %"
                ),
                "AUSSIER",
                if(
                  (
                    production.prod_name LIKE "%HR %"
                    OR production.prod_name LIKE "%HAIRRECIPE%"
                  ),
                  "HAIRRECIPE",
                  if(
                    (
                      production.prod_name LIKE "%HERBA%"
                      OR production.prod_name LIKE "%HESS%"
                    ),
                    "HERBALESSR",
                    if(
                      production.prod_name LIKE "%PERT %",
                      "PERT",
                      "OTHERS"
                    )
                  )
                )
              )
            )
          )
        )
      )
    ) as brand,
    prod.seg_name as Form,
    prod.csu_ind,
    if(
      prod.csu_ind in("CSU", "SFP"),
      "On-going",
      if(prod.csu_ind = "CSUONETIME", "One-time PP", "Others")
    ) as Ongoing_PP,
    SIOC.SIOC_flag, 
    suf.SU_factor,
    production.gr_qty * suf.SU_factor / 1000 as MSU_volume
  FROM
    ap_production_schedule_zprs.production_schedule_asia_star production
    LEFT JOIN dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod ON substr(production.prod_id, 11, 8) = prod.prod_id
    LEFT JOIN dp_demand_forecast_idp.asia_product_dim idp on substr(production.prod_id, 11, 8) = substr(idp.product_id, 11, 8)
    left join userdb_feng_li_4.GC_HC_SIOC_SKU_LIST SIOC on substr(production.prod_id, 11, 8) = SIOC.prod_id
    left join (
      SELECT
        prod_id,
        if(numer = 0, '0', denom / numer) as SU_factor
      FROM
        (
          SELECT
            SUBSTR(id_of_product_material, 11, 8) prod_id,
            MAX(
              denominator_for_alternative_uom_to_buom_conversion_factor
            ) denom,
            MAX(
              numerator_for_alternative_uom_to_buom_conversion_factor
            ) numer
          FROM
            dp_masterdata_g11.marm_units_of_measure_for_material
          Where
            alternative_unit_of_measure_for_stockkeeping_unit = "SU"
          GROUP BY
            SUBSTR(id_of_product_material, 11, 8)
        )
    ) suf ON substr(production.prod_id, 11, 8) = suf.prod_id
    left join (
      SELECT
        substr(prod_id, 11, 8) as MaterialCode,
        First(tdc_val_subsector_name) as Category
      FROM
        dp_osi_bw_global.inventory_part_final_pq
      group by
        substr(prod_id, 11, 8)
    ) Inv on substr(production.prod_id, 11, 8) = Inv.MaterialCode
  WHERE
    plan_plant_id in (
      "0386",
      "1864",
      "A868",
      "9264",
      "A684",
      "A685",
      "A743",
      "A727",
      "8513",
      "5740"
    )
    AND UPPER(Inv.Category) LIKE "%HAIR%"
    AND base_uom in ("EA", "CS")
    AND curr_flag = "Y"
    AND (
      UPPER(prod.prod_4_name) LIKE "%HAIR%"
      OR idp.product_brand_name IN (
        "VIDALSASON",
        "HD&SHLDRS",
        "PANTENE",
        "HAIRRECIPE",
        "REJOICE",
        "PERT",
        "HERBALESSR",
        "AUSSIER"
      )
      OR production.prod_name LIKE "HS %"
      OR production.prod_name LIKE "% HS %"
      OR (
        production.prod_name LIKE "%H&S%"
        AND (NOT production.prod_name LIKE "%SFG%")
      )
      OR production.prod_name LIKE "%RJC %"
      OR production.prod_name LIKE "%REJ %"
      OR UPPER(production.prod_name) LIKE "%REJOICE%"
      OR (
        production.prod_name LIKE "%PTN %"
        AND (NOT production.prod_name LIKE "OLAY%")
      )
      OR production.prod_name LIKE "%PNT %"
      OR production.prod_name LIKE "%PANTENE%"
      OR production.prod_name LIKE "%VS %"
      OR production.prod_name LIKE "%VIDALSASON%"
      OR production.prod_name LIKE "%AUSSIE%"
      OR production.prod_name LIKE "AU %"
      OR production.prod_name LIKE "% AU %"
      OR production.prod_name LIKE "HERBA%"
      OR production.prod_name LIKE "%HESS%"
      OR (
        production.prod_name LIKE "% HERBA%"
        AND (NOT production.prod_name LIKE "ARIEL%")
        AND (NOT production.prod_name LIKE "CR%")
        AND (NOT production.prod_name LIKE "OR%")
        AND (NOT production.prod_name LIKE "CS%")
        AND (NOT production.prod_name LIKE "%CREST %")
        AND (NOT production.prod_name LIKE "OB%")
      )
      OR production.prod_name LIKE "PERT %"
      OR production.prod_name LIKE "% PERT %"
      OR production.prod_name LIKE "HR %"
      OR production.prod_name LIKE "% HR %"
      OR production.prod_name LIKE "%HAIRRECIPE%"
      OR production.prod_name LIKE "%SHM%"
      OR (
        production.prod_name LIKE "%COND%"
        AND (NOT production.prod_name LIKE "%SFG%")
      )
      OR production.prod_name LIKE "%STYLING%"
    )
    AND NOT Inv.Category IN (
      "ORALCARE",
      "PROFSALON",
      "APPLIANCES",
      "SKINPERSCR",
      "DISCSNACKS",
      "COSMETICS",
      "Discontinued Prestige",
      "PRESTIGE",
      "SHAVECARE",
      "FABRICCARE",
      "CORPINVFND",
      "ZINCTVHCLR",
      "FEMCARE"
    )
    AND NOT Inv.Category LIKE "%Discontinued%Cosmetics%"
    AND NOT Inv.Category LIKE "%Discontinued%Professional%Salon%"
    AND NOT Inv.Category LIKE "%Oral%Care%"
    AND NOT Inv.Category LIKE "%Skin%and%Personal%" --AND (NOT production.prod_name LIKE "%SFG%")
    --AND (NOT prod.prod_4_name IN ("Skin and Personal Care","Oral Care"))
)