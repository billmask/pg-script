select pg_size_pretty(count(bufferid::bigint)*8192::bigint) as "Buffer Unused" from pg_buffercache where relfilenode is null;
