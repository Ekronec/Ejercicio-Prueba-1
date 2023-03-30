
variable b_carga number;
exec :b_carga := 4500;
variable b_movadi1 number;
exec :b_movadi1 := 25000;
variable b_movadi2 number;
exec :b_movadi2 := 40000;
variable b_colacion number;
exec :b_colacion := 25000;
variable b_fecha varchar2;
exec :b_fecha := '20230329';

declare
    v_minid number;
    v_maxid number;
    
    -- uso de varible compuesta
    v_emp empleado%rowtype;
    
    --variables escalares
    v_asianti number;
    v_anti number;
    v_pctanti number;
    v_numcargas number;
    v_asimov number;
    v_pctmov number;
    v_comuna comuna.nombre_comuna%type;
    v_comision number;
    v_total number;
begin
    execute IMMEDIATE 'truncate table HABER_CALC_MES';
    
    
    select min(id_empleado),
           max(id_empleado)
    into v_minid, v_maxid
    from empleado;
    
    loop
        exit when v_minid > v_maxid;
        
        select *
        into v_emp
        from empleado
        where id_empleado = v_minid;
        
        --calculo de la antiguedad del empleado
        v_anti := trunc(months_between(sysdate,v_emp.fecing_emp) / 12);
        
        select porc_bonif
        into v_pctanti
        from porc_bonif_annos_contrato
        where v_anti BETWEEN annos_inferior and annos_superior;
        
        v_asianti := round(v_emp.sueldo_base_emp * v_pctanti);
        
        
        select count(numrut_carga)
        into v_numcargas
        from carga_familiar
        where numrut_emp = v_emp.numrut_emp;
        
        select nombre_comuna
        into v_comuna
        from comuna
        where id_comuna = v_emp.id_comuna;
        
        select porc_mov / 100
        into v_pctmov
        from porc_movilizacion
        where v_emp.sueldo_base_emp between sueldo_base_inf and sueldo_base_sup;
        
        v_asimov := round(v_emp.sueldo_base_emp * v_pctmov) + 
                    case
                        when v_comuna in ( 'La Pintana', 'Cerro Navia', 'Peñalolén') then :b_movadi1
                        when v_comuna in (' Melipilla', 'María Pinto', 'Curacaví', 'Talagante', 'Isla de Maipo', 'Paine') then :b_movadi2
                        else 0
                    end;
                    
        select sum(co.valor_comision) 
        into v_comision
        from comision_venta co join boleta bo
        on  co.nro_boleta = bo.nro_boleta
        where bo.numrut_emp = v_emp.numrut_emp;
        
        v_total :=  v_emp.sueldo_base_emp +v_asianti+(v_numcargas * :b_carga)+v_asimov+:b_colacion+ nvl(v_comision, 0);
        
        pl(v_minid
            ||' '|| v_emp.numrut_emp
            ||' '|| substr(:b_fecha, -4, 2)
            ||' '|| substr(:b_fecha, 1, 4)
            ||' '|| v_emp.sueldo_base_emp
            ||' '|| v_asianti
            ||' '|| (v_numcargas * :b_carga)
            ||' '|| v_asimov
            ||' '|| :b_colacion
            ||' '|| nvl(v_comision, 0)
            ||' '|| v_total
        );
        
        insert into haber_calc_mes
        values (v_minid, v_emp.numrut_emp, substr(:b_fecha, -4, 2) , substr(:b_fecha, 1, 4)
            ,v_emp.sueldo_base_emp, v_asianti, (v_numcargas * :b_carga), v_asimov, :b_colacion, nvl(v_comision, 0), v_total
        );
        
        
        v_minid := v_minid + 10;
    end loop;
    
end;
/