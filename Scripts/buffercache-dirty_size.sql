select pg_size_pretty(count(bufferid::bigint)*8192::bigint) from pg_buffercache where isdirty = 't';
