CREATE OR REPLACE FUNCTION public.taiud_populate_game_servers()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    serverCount int = 0;
    game_port int;
    tv_port int;
    server_ip inet;
    is_region_lan boolean;
BEGIN
    select is_lan into is_region_lan from server_regions where value = NEW.region;

    if(is_region_lan) then
        server_ip = NEW.lan_ip;
    else
        server_ip = NEW.public_ip;
    end if;

    IF TG_OP = 'UPDATE' AND (
        OLD.lan_ip != NEW.lan_ip OR
        OLD.public_ip != NEW.public_ip 
    ) THEN
        UPDATE servers SET host = host(server_ip) WHERE game_server_node_id = NEW.id;
    END IF;

    IF TG_OP = 'UPDATE' AND (
        NEW.enabled = true AND
        (
            OLD.enabled = NEW.enabled AND
            OLD.region = NEW.region AND
            OLD.start_port_range = NEW.start_port_range AND
            OLD.end_port_range = NEW.end_port_range
        )
    ) THEN
        RETURN NEW;
    END IF;

    IF TG_OP != 'INSERT' THEN
        IF EXISTS (SELECT 1 FROM servers WHERE game_server_node_id = NEW.id AND reserved_by_match_id IS NOT NULL) THEN
            RAISE EXCEPTION 'Can not change node details while matches are ongoing. It is recommended to disable node to prevent further usage.' USING ERRCODE = '22000';
        END IF;
    END IF;

    delete from servers where game_server_node_id = NEW.id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    IF NEW.enabled = false OR NEW.start_port_range IS NULL OR NEW.end_port_range IS NULL OR NEW.public_ip IS NULL THEN
        RETURN NEW;
    END IF;
      

    game_port = NEW.start_port_range;

    WHILE game_port < NEW.end_port_range LOOP
        serverCount = serverCount + 1;

        INSERT INTO servers (host, label, rcon_password, port, tv_port, api_password, game_server_node_id, region)
        VALUES (host(server_ip), CONCAT('on-demand-', serverCount), gen_random_uuid()::text::bytea, game_port, game_port + 1, gen_random_uuid(), NEW.id, NEW.region);

        game_port = game_port + 2;
    END LOOP;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS taiud_populate_game_servers ON public.game_server_nodes;
CREATE TRIGGER taiud_populate_game_servers AFTER INSERT OR UPDATE OR DELETE ON public.game_server_nodes FOR EACH ROW EXECUTE FUNCTION public.taiud_populate_game_servers();
