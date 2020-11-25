DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_Prod_Master_Data;
CREATE TABLE userdb_feng_li_4.GC_HC_Prod_Master_Data As (
  SELECT
    prod.prod_id,
    prod.prod_3_name as Category,
    prod.prod_4_name as Sub_Category,
    prod.sub_brand_desc,
    prod.seg_name as Form,
    prod.prime_pk_tp_desc as package_type,
    prod.csu_ind,
    if(
      prod.csu_ind in("CSU", "SFP"),
      "On-going",
      if(prod.csu_ind = "CSUONETIME", "One-time PP", "Others")
    ) as Ongoing_PP,
    if(
      NOT idp.attribute8 LIKE "%0MX%"
      AND NOT prod.globl_form_desc = "Mixed"
      AND NOT prod.cb1_desc = "Mixed"
      AND NOT prod.name LIKE "%+%",
      "single bottle",
      "pack"
    ) as single_pack,
    prod.name as EN_Desc,
    life.life_cycle_scope as Country,
    prod.globl_form_desc,
    prod.cb1_desc,
    prod.custm_type_desc,
    prod.unit_sz_as_desc,
    prod.brand_detl_desc,
    prod.prod_csu_type_code,
    prod.matl_type_code,
    prod.brand_abbr_code,
    life.life_cycle_status,
    life.market_segmentation,
    idp.product_brand_name as brand,
    IF(
      idp.product_brand_name = "REJOICE",
      IF(idp.attribute2 = "DAILYCARE", "RJC FC", "RJC EC"),
      product_brand_name
    ) AS sub_brand,
    idp.attribute5,
    idp.attribute6 as variant,
    idp.attribute7 as package,
    idp.attribute8 as size,
    substr(idp.ifam3, 1, 10) SFU,
    idp.uom,
    idp.alt_uom,
    idp.conv_uom_alt_rate su_factor,
    case.cs_barcode,
      case.cs_length,
        case.cs_width,
          case.cs_height,
            case.cs_volume,
              case.cs_volume_unit,
                case.cs_gross_weight,
                  case.cs_weight_unit,
                    item.it_barcode,
                    item.it_length,
                    item.it_width,
                    item.it_height,
                    item.it_volume,
                    item.it_volume_unit,
                    item.it_gross_weight,
                    item.it_weight_unit,
                    if(
                      idp.product_brand_name = "HD&SHLDRS",
                      if(
                        UPPER(prod.name) LIKE "%HELENA%"
                        OR UPPER(prod.name) LIKE "%AHF%",
                        "AHF",
                        if(
                          UPPER(prod.name) LIKE "%PERFUME%",
                          "H&S Perfume",
                          if(
                            UPPER(prod.name) LIKE "%SUPREME%",
                            "H&S Supreme",
                            "H&S Base"
                          )
                        )
                      ),
                      if(
                        idp.product_brand_name = "PANTENE",
                        if(
                          UPPER(prod.name) LIKE "%3MM%"
                          AND (NOT UPPER(prod.name) LIKE "%SHM%"),
                          "PTN 3MM",
                          if(
                            UPPER(prod.name) LIKE "%SCALP%"
                            AND (NOT UPPER(prod.name) LIKE "%SHM%"),
                            "PTN Charcoal",
                            if(
                              UPPER(prod.name) LIKE "%GIN%"
                              AND (NOT UPPER(prod.name) LIKE "%MICELLAR%"),
                              "PTN GINZA",
                              if(
                                UPPER(prod.name) LIKE "%MARILYN%",
                                "PTN Marilyn",
                                if(
                                  UPPER(prod.name) LIKE "%MICELLAR%"
                                  OR UPPER(prod.name) LIKE "%DETOX%",
                                  "PTN MW",
                                  "PTN Base"
                                )
                              )
                            )
                          )
                        ),
                        if(
                          idp.product_brand_name = "REJOICE"
                          OR idp.product_brand_name = "PERT",
                          if(
                            UPPER(prod.name) LIKE "%AIR%FRESH%"
                            OR UPPER(prod.name) LIKE "%OIL%CONTROL%FRESH%",
                            "Rej MW",
                            if(
                              UPPER(prod.name) LIKE "%MW SMOOTH%"
                              OR UPPER(prod.name) LIKE "%MW AD%",
                              "Rej Biwako",
                              if(
                                UPPER(prod.name) LIKE "%FLORA%"
                                OR UPPER(prod.name) LIKE "%TROPICAL%"
                                OR UPPER(prod.name) LIKE "%OCEAN%",
                                "Rej Freya",
                                if(
                                  UPPER(prod.name) LIKE "%WITCH%",
                                  "Rej Oil",
                                  if(
                                    UPPER(prod.name) LIKE "%LOVE%IN%PARIS%"
                                    OR UPPER(prod.name) LIKE "%MEDI%BREEZE%",
                                    "Rej Sapphire",
                                    if(
                                      IF(
                                        idp.product_brand_name = "REJOICE",
                                        IF(idp.attribute2 = "DAILYCARE", "RJC FC", "RJC EC"),
                                        product_brand_name
                                      ) = "Rej FC",
                                      "Rej FC",
                                      "Rej EC Base"
                                    )
                                  )
                                )
                              )
                            )
                          ),
                          if(
                            idp.product_brand_name = "VIDALSASON",
                            if(
                              UPPER(prod.name) LIKE "%LEDZ%",
                              "VS Led Zeppelin",
                              if(
                                UPPER(prod.name) LIKE "%NUDE%"
                                OR UPPER(prod.name) LIKE "%QUEEN%"
                                OR UPPER(prod.name) LIKE "%FOAM%"
                                OR UPPER(prod.name) LIKE "%SCALP%",
                                "VS Queen",
                                if(
                                  UPPER(prod.name) LIKE "%STYLING REMOVER%"
                                  OR UPPER(prod.name) LIKE "%CURL STRENTHEN%"
                                  OR UPPER(prod.name) LIKE "%COLOR KEEPER%",
                                  "VS Spicy Girl",
                                  if(
                                    prod.seg_name LIKE "%Styling%"
                                    OR prod.seg_name LIKE "%Spray%",
                                    "VS Styling",
                                    "VS Base"
                                  )
                                )
                              )
                            ),
                            if(
                              idp.product_brand_name = "AUSSIER",
                              if(
                                prod.globl_form_desc = "Dry Shampoo",
                                "Aussie Dry Shampoo",
                                "Aussie Base"
                              ),
                              idp.product_brand_name
                            )
                          )
                        )
                      )
                    ) as Brand_Tier,
                    if(
                      idp.product_brand_name in ("AUSSIER", "HERBALESSR", "HAIRRECIPE"),
                      "More",
                      if(
                        idp.product_brand_name in (
                          "HD&SHLDRS",
                          "PANTENE",
                          "REJOICE",
                          "PERT",
                          "VIDALSASON"
                        ),
                        if(
                          if(
                            idp.product_brand_name = "HD&SHLDRS",
                            if(
                              UPPER(prod.name) LIKE "%HELENA%"
                              OR UPPER(prod.name) LIKE "%AHF%",
                              "AHF",
                              if(
                                UPPER(prod.name) LIKE "%PERFUME%",
                                "H&S Perfume",
                                if(
                                  UPPER(prod.name) LIKE "%SUPREME%",
                                  "H&S Supreme",
                                  "H&S Base"
                                )
                              )
                            ),
                            if(
                              idp.product_brand_name = "PANTENE",
                              if(
                                UPPER(prod.name) LIKE "%3MM%"
                                AND (NOT UPPER(prod.name) LIKE "%SHM%"),
                                "PTN 3MM",
                                if(
                                  UPPER(prod.name) LIKE "%SCALP%"
                                  AND (NOT UPPER(prod.name) LIKE "%SHM%"),
                                  "PTN Charcoal",
                                  if(
                                    UPPER(prod.name) LIKE "%GIN%"
                                    AND (NOT UPPER(prod.name) LIKE "%MICELLAR%"),
                                    "PTN GINZA",
                                    if(
                                      UPPER(prod.name) LIKE "%MARILYN%",
                                      "PTN Marilyn",
                                      if(
                                        UPPER(prod.name) LIKE "%MICELLAR%"
                                        OR UPPER(prod.name) LIKE "%DETOX%",
                                        "PTN MW",
                                        "PTN Base"
                                      )
                                    )
                                  )
                                )
                              ),
                              if(
                                idp.product_brand_name = "REJOICE"
                                OR idp.product_brand_name = "PERT",
                                if(
                                  UPPER(prod.name) LIKE "%AIR%FRESH%"
                                  OR UPPER(prod.name) LIKE "%OIL%CONTROL%FRESH%",
                                  "Rej MW",
                                  if(
                                    UPPER(prod.name) LIKE "%MW SMOOTH%"
                                    OR UPPER(prod.name) LIKE "%MW AD%",
                                    "Rej Biwako",
                                    if(
                                      UPPER(prod.name) LIKE "%FLORA%"
                                      OR UPPER(prod.name) LIKE "%TROPICAL%"
                                      OR UPPER(prod.name) LIKE "%OCEAN%",
                                      "Rej Freya",
                                      if(
                                        UPPER(prod.name) LIKE "%WITCH%",
                                        "Rej Oil",
                                        if(
                                          UPPER(prod.name) LIKE "%LOVE%IN%PARIS%"
                                          OR UPPER(prod.name) LIKE "%MEDI%BREEZE%",
                                          "Rej Sapphire",
                                          if(
                                            IF(
                                              idp.product_brand_name = "REJOICE",
                                              IF(idp.attribute2 = "DAILYCARE", "RJC FC", "RJC EC"),
                                              product_brand_name
                                            ) = "Rej FC",
                                            "Rej FC",
                                            "Rej EC Base"
                                          )
                                        )
                                      )
                                    )
                                  )
                                ),
                                if(
                                  idp.product_brand_name = "VIDALSASON",
                                  if(
                                    UPPER(prod.name) LIKE "%LEDZ%",
                                    "VS Led Zeppelin",
                                    if(
                                      UPPER(prod.name) LIKE "%NUDE%"
                                      OR UPPER(prod.name) LIKE "%QUEEN%"
                                      OR UPPER(prod.name) LIKE "%FOAM%"
                                      OR UPPER(prod.name) LIKE "%SCALP%",
                                      "VS Queen",
                                      if(
                                        UPPER(prod.name) LIKE "%STYLING REMOVER%"
                                        OR UPPER(prod.name) LIKE "%CURL STRENTHEN%"
                                        OR UPPER(prod.name) LIKE "%COLOR KEEPER%",
                                        "VS Spicy Girl",
                                        if(
                                          prod.seg_name LIKE "%Styling%"
                                          OR prod.seg_name LIKE "%Spray%",
                                          "VS Styling",
                                          "VS Base"
                                        )
                                      )
                                    )
                                  ),
                                  idp.product_brand_name
                                )
                              )
                            )
                          ) LIKE "%Base%",
                          "Core",
                          "Core+"
                        ),
                        "Other Brand"
                      )
                    ) as Core_Coreplus_More,
                    sos.start_of_shpmt_day,
                    sos.end_of_shpmt_day,
                    ebp.customer_EBP_FLAG,
                    ebp.customer_EBP,
                    SIOC.SIOC_flag,
                    mara.total_shelf_life --formula.technology_family,
                    --formula.chassis,
                    --formula.formula_gcas,
                    --formula.formula_long_description,
                    --bottle.bottle_id,
                    --bottle.bottle_desc,
                    --bottle.bottle_mpmp,
                    --bottle.bottle_mpmp_desc,
                    --bottle.packaging_size bottle_size,
                    --bottle.bottle_type,
                    --bottle.packaging_size_uom bottle_size_uom,
                    --bottle.RD_global_shape_name RD_bottle_shape_name,
                    --closure.closure_id,
                    --closure.closure_desc,
                    --closure.closure_mpmp,
                    --closure.closure_mpmp_desc,
                    --closure.packaging_size closure_size,
                    --closure.closure_type,
                    --closure.packaging_size_uom closure_size_uom,
                    --closure.RD_global_shape_name RD_closure_shape_name,
                    --sleeve.sleeve_id,
                    --sleeve.sleeve_desc,
                    --sleeve.sleeve_mpmp,
                    --sleeve.sleeve_mpmp_desc
                    From
                      dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod,
                      dp_masterdata_g11.ztxxptmelf_fpc_external_life_cycle life
                      left join dp_demand_forecast_idp.asia_product_dim idp on prod.prod_id = substr(idp.product_id, 11, 8)
                      left join (
                        SELECT
                          SUBSTR(id_of_product_material, 11, 8) prod_id,
                          MAX(international_article_number_ean_upc) cs_barcode,
                          MAX(object_length) cs_length,
                          MAX(object_width) cs_width,
                          MAX(height) cs_height,
                          MAX(volume) cs_volume,
                          MAX(Volume_unit) cs_volume_unit,
                          MAX(gross_weight) cs_gross_weight,
                          MAX(weight_unit) cs_weight_unit
                        FROM
                          dp_masterdata_g11.marm_units_of_measure_for_material
                        Where
                          alternative_unit_of_measure_for_stockkeeping_unit = "CS"
                        GROUP BY
                          SUBSTR(id_of_product_material, 11, 8)
                      ) case
                        on prod.prod_id =case.prod_id
                          left join (
                            SELECT
                              SUBSTR(id_of_product_material, 11, 8) prod_id,
                              MAX(international_article_number_ean_upc) it_barcode,
                              MAX(object_length) it_length,
                              MAX(object_width) it_width,
                              MAX(height) it_height,
                              MAX(volume) it_volume,
                              MAX(Volume_unit) it_volume_unit,
                              MAX(gross_weight) it_gross_weight,
                              MAX(weight_unit) it_weight_unit
                            FROM
                              dp_masterdata_g11.marm_units_of_measure_for_material
                            Where
                              alternative_unit_of_measure_for_stockkeeping_unit = "IT"
                            GROUP BY
                              SUBSTR(id_of_product_material, 11, 8)
                          ) item on prod.prod_id = item.prod_id
                          left join userdb_feng_li_4.gc_hc_sku_sos_eos sos on prod.prod_id = sos.prod_id
                          AND life.life_cycle_scope = sos.country
                          left join userdb_feng_li_4.gc_hc_sku_customer_ebp ebp on prod.prod_id = ebp.prod_id
                          AND life.life_cycle_scope = ebp.country
                          left join userdb_feng_li_4.GC_HC_SIOC_SKU_LIST SIOC on prod.prod_id = SIOC.prod_id
                          left join dp_masterdata_g11.mara_general_material_data mara on prod.prod_id = substr(mara.id_of_product_material, 11, 8)
                          left join userdb_feng_li_4.othersourcing_hc_formula_list formula on prod.prod_id = formula.name
                          left join userdb_feng_li_4.othersourcing_hc_bottle_lists bottle on prod.prod_id = bottle.prod_id
                          left join userdb_feng_li_4.othersourcing_hc_closure_lists closure on prod.prod_id = closure.prod_id
                          left join userdb_feng_li_4.othersourcing_hc_sleeve_lists sleeve on prod.prod_id = sleeve.prod_id
                          where
                            prod.prod_id = substr(life.id_of_product_material, 11, 8)
                            and UPPER(prod.prod_4_name) LIKE "%HAIR%"
                            and life.life_cycle_scope in ("CN", "HK", "TW")
                        )