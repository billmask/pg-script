select now() - pg_last_xact_replay_timestamp() AS replication_delay;

SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0
ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())::INTEGER END
AS replication_lag;

SELECT pg_last_xlog_receive_location() receive, pg_last_xlog_replay_location() replay, (extract(epoch FROM now()) -  extract(epoch 
FROM pg_last_xact_replay_timestamp()))::int lag;