create or replace procedure pl(
    cadena varchar2
)
as
begin
    DBMS_OUTPUT.PUT_LINE(cadena);
end;
/

drop public synonym pl;
create public synonym pl for pl;

drop user alumno cascade;
create user alumno IDENTIFIED by "Duoc.Semestre03"
quota unlimited on data;
grant create session, RESOURCE to alumno;
grant execute on pl to alumno;