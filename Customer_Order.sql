DROP TABLE IF EXISTS userdb_feng_li_4.GC_HC_Customer_Order;
CREATE TABLE userdb_feng_li_4.GC_HC_Customer_Order As (
  SELECT
    substr(zder.sales_document, 2, 9) sales_document,
    zder.sales_document_item,
    zder.customer_purchase_order_number,
    VBUP.order_status,
    zder.order_date,
    --zder.order_status,
    zder.statistical_delivery_date,
    zder.requested_delivery_date,
    zder.sold_to_party,
    zder.ship_to_party,
    --zder.customer,
    zder.banner as Banner,
    zder.plant,
    zder.order_reason as Order_Type,
    zder.customer_group_5 as discount,
    zder.material_number,
    zder.description,
    zder.Category,
    zder.material_number_used_by_customer,
    MARM3.barcode,
    zder.spaced,
    LIPS.delivery,
    ifnull(zder.cumulative_order_quantity_in_sales_units, 0) as Order_qty,
    zder.sales_unit_of_measure,
    ifnull(
      zder.cumulative_confirmed_quantity_in_sales_unit,
      0
    ) as Confirm_qty,
    ifnull(LIPS.actual_quantity_delivered_in_sales_units, 0) as delivered_qty,
    ifnull(LIPS.actual_quantity_GI, 0) as shipped_qty,
    ifnull(zder.su_factor, 0) * ifnull(zder.cumulative_order_quantity_in_sales_units, 0) as Order_qty_SU,
    ifnull(zder.su_factor, 0) * ifnull(
      zder.cumulative_confirmed_quantity_in_sales_unit,
      0
    ) as Confirm_qty_SU,
    ifnull(LIPS.actual_quantity_delivered_in_sales_units, 0) * ifnull(zder.su_factor, 0) as delivered_qty_SU,
    ifnull(LIPS.actual_quantity_GI, 0) * ifnull(zder.su_factor, 0) as shipped_qty_SU,
    ifnull(
      zder.cumulative_confirmed_quantity_in_sales_unit,
      0
    ) * ifnull(zder.freight_ton_factor, 0) as freight_ton,
    ifnull(
      zder.cumulative_confirmed_quantity_in_sales_unit,
      0
    ) * ifnull(zder.freight_volume_factor, 0) as freight_volume,
    ifnull(Cut.cut_qty, 0) as cut_qty,
    ifnull(cut07.cut_qty, 0) as cut_qty_07,
    zder.GIV as GIV,
    --(zder.cumulative_order_quantity_in_sales_units - ifnull(cut.cut_qty,0)) as `有效下单数量(新)`,
    --ifnull(cut07.cut_qty,0) as `07cut_qty_sales_unit`,
    --zder.qty_su AS `下单数量(SU)`,
    --zder.qty_su / zder.cumulative_order_quantity_in_sales_units * (zder.cumulative_confirmed_quantity_in_sales_unit) as `有效下单数量(SU)`,
    --zder.qty_su / zder.cumulative_order_quantity_in_sales_units *ifnull(LIPS.actual_quantity_delivered_in_sales_units,0) as `分货数量(SU)`,
    --zder.qty_su / zder.cumulative_order_quantity_in_sales_units *ifnull(LIPS.actual_quantity_GI,0) as `送货数量(SU)`,
    --zder.GIV/zder.cumulative_confirmed_quantity_in_sales_unit  as Unit_price,
    --(ifnull(LIPS.actual_quantity_delivered_in_sales_units,0)+ifnull(cut07.cut_qty,0)) * ifnull(zder.su_factor,0) as Original_Delivery_MSU,
    su_factor as su_factor,
    zder.sd_document_currency as currency,
    if(
      zder.customer = 'JINGDONG',
      'JINGDONG',
      if(
        ecust.eCOMBanner is null,
        zder.customer,
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
      zder.channel = "JD"
      or not ecust.eCOMBanner is null,
      'iOMNI Online',
      zder.channel
    ) as channel
  FROM
    (
      SELECT
        orders.*,
        prod.name description,
        orders.cumulative_order_quantity_in_sales_units * ifnull(MARM1.factor / MARM2.factor, 0) as qty_su,
        ifnull(MARM1.factor / MARM2.factor, 0) as su_factor,
        ifnull(MARM3.factor / MARM2.factor, 0) as cs_factor,
        ifnull(MARM1.factor / MARM3.factor, 0) as SU_CS,
        ifnull(
          MARM3.factor / MARM2.factor *(MARM3.volume * MARM3.DM3_rate) / 1000,
          0
        ) as freight_volume_factor,
        ifnull(
          MARM3.factor / MARM2.factor *(MARM3.gross_weight * MARM3.KG_rate / 1000),
          0
        ) as freight_ton_factor,
        --箱子的条码?
        MARM3.CS_Barcode AS CS_Barcode,
        weekofyear(
          to_date(
            concat_ws(
              '-',
              substr(cast(orders.order_date as string), 1, 4),
              substr(cast(orders.order_date as string), 5, 2),
              substr(cast(orders.order_date as string), 7, 2)
            )
          )
        ) as shmpt_wk,
        substr(orders.order_date, 1, 4) as shpmt_year,
        cust.name_1_1 as customer,
        cust.sort_field as banner,
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
                    if(
                      substr(cust.group_key, 2, 1) = "0",
                      'iOMNI Offline',
                      if(
                        substr(cust.group_key, 2, 1) = "5",
                        'iOMNI Online',
                        if(substr(cust.group_key, 2, 1) = "8", 'RR', 'Others')
                      )
                    )
                  )
                )
              )
            )
          )
        ) as channel,
        prod.prod_4_name as Category,
        prod.prod_5_name as Form,
        prod.sub_brand_desc as sub_brand,
        seg.market_segmentation as spaced
      FROM
        (
          SELECT
            VBAK.sales_document,
            VBAK.customer_purchase_order_number,
            --AUFK.Order_Status,
            VBAK.sold_to_party,
            VBPA.customer_number as ship_to_party,
            VBAP.plant_own_or_external as plant,
            VBAP.sales_document_item,
            VBAP.material_number_used_by_customer,
            VBAK.customer_group_5,
            --VBAP.route,
            substr(VBAP.id_of_product_material, 11, 8) as material_number,
            --VBAP.short_text_for_sales_order_item as description,
            VBAP.sales_unit_of_measure,
            VBAP.sd_document_currency,
            VBAK.date_on_which_record_was_created as order_date,
            vbak.material_staging_availability_date material_available_date,
            VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in as statistical_delivery_date,
            VBAK.requested_delivery_date,
            IF(
              VBAP.material_group_5 = "001",
              "CS",
              IF(VBAP.material_group_5 = "003", "SW", "IT")
            ) as barcode_type,
            VBAK.order_reason_reason_for_the_business_transaction as order_reason,
            sum(VBAP.cumulative_order_quantity_in_sales_units) as cumulative_order_quantity_in_sales_units,
            SUM(VBAP.cumulative_confirmed_quantity_in_sales_unit) as cumulative_confirmed_quantity_in_sales_unit,
            SUM(
              VBAP.subtotal_1_from_pricing_procedure_for_condition
            ) as GIV
          FROM
            (
              SELECT
                *
              FROM
                dp_osi_ap_ecc.vbak_sales_document_header_data VBAK
              WHERE
                VBAK.sales_document_type IN ("Z001", "ZF01") --AND     VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in>='20200301'
                --- AND  substring(VBAK.AUDAT,5,2)=substring(string(now()),6,2)
                ---  AND  left(VBAK.AUDAT,4)=left(string(now()),4)
                AND VBAK.sales_organization in ('CN21', 'CN12')
                AND VBAK.distribution_channel IN ("01", "02")
                AND VBAK.division = "01" --AND VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in>=concat(substr((select current_date() ),1,4),substr((select current_date()),6,2),'01')
                --AND substr(VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in,1,6) IN ('202002','202003')
                --AND substr(VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in,1,6)=concat(substr((select current_date() ),1,4),substr((select current_date()),6,2))
                --AND VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in<=concat(substr((select current_date() ),1,4),substr((select current_date()),6,2),substr((select current_date()),9,2))
            ) VBAK
            LEFT JOIN (
              SELECT
                *
              FROM
                dp_osi_ap_ecc.vbap_sales_document_item_data
              WHERE
                higher_level_item_in_bill_of_material_structures = '000000'
            ) AS VBAP ON VBAK.sales_document = VBAP.sales_document
            LEFT JOIN (
              SELECT
                *
              FROM
                dp_osi_ap_ecc.vbpa_sales_document_partner
              WHERE
                item_number_of_the_sd_document = '000000'
                AND partner_function = 'WE'
            ) AS VBPA ON VBAK.sales_document = VBPA.sales_and_distribution_document
          GROUP BY
            VBAK.sales_document,
            VBAK.customer_purchase_order_number,
            VBAK.sold_to_party,
            VBPA.customer_number,
            VBAP.plant_own_or_external,
            VBAP.sales_document_item,
            VBAP.material_number_used_by_customer,
            VBAK.customer_group_5,
            --VBAP.route,
            substr(VBAP.id_of_product_material, 11, 8),
            VBAP.short_text_for_sales_order_item,
            VBAP.sales_unit_of_measure,
            VBAP.sd_document_currency,
            VBAK.date_on_which_record_was_created,
            vbak.material_staging_availability_date,
            VBAK.document_date_date_received_sent_date_on_which_the_source_for_the_sales_order_it_can_be_acustomer_purchase_order_came_in,
            VBAK.requested_delivery_date,
            IF(
              VBAP.material_group_5 = "001",
              "CS",
              IF(VBAP.material_group_5 = "003", "SW", "IT")
            ),
            VBAK.order_reason_reason_for_the_business_transaction
        ) orders
        left join --a constrain on alternative_unit_of_measure_for_stockkeeping_unit = 'SU'
        (
          select
            substr(id_of_product_material, 11, 8) as material_number,
            alternative_unit_of_measure_for_stockkeeping_unit as unit,
            denominator_for_alternative_uom_to_buom_conversion_factor / numerator_for_alternative_uom_to_buom_conversion_factor as factor
          FROM
            dp_osi_ap_ecc.marm_units_of_measure_for_material
          WHERE
            alternative_unit_of_measure_for_stockkeeping_unit = 'SU'
        ) MARM1 on orders.material_number = MARM1.material_number
        left join (
          SELECT
            substr(id_of_product_material, 11, 8) as material_number,
            alternative_unit_of_measure_for_stockkeeping_unit as unit,
            denominator_for_alternative_uom_to_buom_conversion_factor / numerator_for_alternative_uom_to_buom_conversion_factor as factor
          FROM
            dp_osi_ap_ecc.marm_units_of_measure_for_material
        ) MARM2 on orders.material_number = MARM2.material_number
        AND MARM2.unit = orders.sales_unit_of_measure
        left join -- a constrain on Alternative_Unit_of_Measure_for_Stockkeeping_Unit = 'CS'
        (
          SELECT
            right(id_of_product_material, 8) as material_number,
            Alternative_Unit_of_Measure_for_Stockkeeping_Unit as unit,
            denominator_for_alternative_uom_to_buom_conversion_factor / numerator_for_alternative_uom_to_buom_conversion_factor as factor,
            volume as volume,
            Volume_unit as Volume_unit,
            Gross_weight as Gross_Weight,
            Weight_unit as Weight_Unit,
            international_article_number_ean_upc as CS_Barcode,
            case
              Volume_unit
              when 'CM3' THEN 0.001
              when 'M3' THEN 1000
              else 1
            END AS DM3_rate,
            Case
              Weight_unit
              WHEN 'G' THEN 0.001
              when 'KG' THEN 1
              ELSE -1
            END AS KG_rate
          FROM
            dp_masterdata_g11.marm_units_of_measure_for_material
          WHERE
            Alternative_Unit_of_Measure_for_Stockkeeping_Unit = 'CS'
        ) MARM3 ON orders.material_number = MARM3.material_number
        left join -- 以SKU为单位的产品详细描述; 每一个prod_id都是unique的
        dp_direct_shpmt_cfr.shpmt_prod_5005_day_fdim prod on orders.material_number = prod.prod_id
        left join dp_masterdata_g11.ztxxptmelf_fpc_external_life_cycle seg on orders.material_number = substr(seg.id_of_product_material, 11, 8)
        left join dp_osi_ap_ecc.kna1_general_data_in_customer_master cust on orders.ship_to_party = cust.customer_number
      WHERE
        seg.life_cycle_scope = 'CN'
        and UPPER(prod.prod_4_name) LIKE "%HAIR%"
    ) zder
    left join (
      SELECT
        substr(id_of_product_material, 11, 8) as material_number,
        alternative_unit_of_measure_for_stockkeeping_unit,
        international_article_number_ean_upc as barcode
      FROM
        dp_osi_ap_ecc.marm_units_of_measure_for_material
    ) MARM3 on MARM3.alternative_unit_of_measure_for_stockkeeping_unit = zder.barcode_type
    and zder.material_number = MARM3.material_number
    left join (
      select
        LIPS2.document_number_of_the_reference_document as document_number_of_the_reference_document,
        LIPS2.item_number_of_the_reference_item as item_number_of_the_reference_item,
        MAX(LIPS2.delivery) as delivery,
        sum(LIPS2.actual_quantity_delivered_in_sales_units) as actual_quantity_delivered_in_sales_units,
        sum(LIPS2.actual_quantity_GI) as actual_quantity_GI
      from
        (
          select
            lips1.document_number_of_the_reference_document,
            lips1.item_number_of_the_reference_item,
            lips1.delivery_document as delivery,
            --lips1.delivery_item,
            sum(lips1.actual_quantity_delivered_in_sales_units) as actual_quantity_delivered_in_sales_units,
            sum(VBFA.referenced_quantity_in_base_unit_of_measure) / avg(
              lips1.numerator_factor_for_conversion_of_sales_quantity_into_sku * lips1.denominator_divisor_for_conversion_of_sales_qty_into_sku
            ) As actual_quantity_GI
          from
            dp_osi_ap_ecc.lips_sd_document_delivery_item_data lips1
            left join (
              SELECT
                *
              FROM
                dp_osi_ap_ecc.vbfa_sales_document_flow
              WHERE
                Document_category_of_subsequent_document = 'R'
                AND Quantity_is_calculated_positively_negatively_or_not_at_all = '+'
            ) VBFA on lips1.delivery_document = VBFA.originating_document
            and lips1.delivery_item = VBFA.originating_item
          where
            LIPS1.simp_chng_type_code <> "D"
          group by
            document_number_of_the_reference_document,
            item_number_of_the_reference_item,
            lips1.delivery_document
        ) LIPS2
      group by
        LIPS2.document_number_of_the_reference_document,
        LIPS2.item_number_of_the_reference_item
    ) LIPS on zder.sales_document = LIPS.document_number_of_the_reference_document
    AND zder.sales_document_item = LIPS.item_number_of_the_reference_item
    left join (
      SELECT
        delivery_document,
        order_item_number,
        MAX(order_status) order_status
      FROM
        dp_osi_ap_ecc.vbup_sales_document_item_status
      GROUP BY
        delivery_document,
        order_item_number
    ) VBUP on zder.sales_document = VBUP.delivery_document
    AND zder.sales_document_item = VBUP.order_item_number
    left join (
      SELECT
        VBELN as sales_document,
        right(MATNR, 8) as material_number,
        sum(CUTQTY) as cut_qty
      FROM
        dp_osi_ap_ecc.ZVXX_CFR_ORDERS zvxx
      where
        VKORG = 'CN21'
        and ZZVXXABGRU <> '07'
        and ZZVXXABGRU <> 'D4'
      group by
        VBELN,
        right(MATNR, 8)
    ) cut On zder.sales_document = cut.sales_document
    AND zder.material_number = cut.material_number
    left join (
      SELECT
        VBELN as sales_document,
        right(MATNR, 8) as material_number,
        sum(CUTQTY) as cut_qty
      FROM
        dp_osi_ap_ecc.ZVXX_CFR_ORDERS
      where
        VKORG = 'CN21'
        and ZZVXXABGRU in ('07', 'D4')
      group by
        VBELN,
        right(MATNR, 8)
    ) cut07 On zder.sales_document = cut07.sales_document
    and zder.material_number = cut07.material_number
    left join userdb_feng_li_4.uploaded_ecom_shipto_list ecust on zder.ship_to_party = ecust.`Ship-to Code`
)