CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA bedrock_integration;

CREATE ROLE bedrock_user WITH PASSWORD 'Admin@123' LOGIN;

GRANT ALL ON SCHEMA bedrock_integration to bedrock_user;

ALTER DATABASE postgres SET search_path TO bedrock_integration, public;

CREATE TABLE bedrock_integration.bedrock_kb (id uuid PRIMARY KEY, embedding vector(1536), chunks text, metadata json);

GRANT ALL PRIVILEGES ON TABLE bedrock_integration.bedrock_kb TO bedrock_user;

GRANT ALL ON table bedrock_integration.bedrock_kb to bedrock_user;

CREATE INDEX ON bedrock_integration.bedrock_kb USING hnsw (embedding vector_cosine_ops);