CREATE OR REPLACE FUNCTION public.verify_region_veto_pick(match_region_veto_pick match_region_veto_picks) RETURNS VOID
    LANGUAGE plpgsql
    AS $$
DECLARE
    lineup_id uuid;
    _match matches;
BEGIN
    select * into _match from matches where id = match_region_veto_pick.match_id;

    -- Get the lineup_id for the match
    SELECT * INTO lineup_id FROM get_region_veto_picking_lineup_id(_match);

    -- Check if the lineup_id matches the lineup_id provided in the match_region_veto_pick veto
    IF match_region_veto_pick.match_lineup_id != lineup_id THEN
        RAISE EXCEPTION 'Expected other lineup for %', lineup_id USING ERRCODE = '22000';
    END IF;
END;
$$;