create extension vector;

create table tns (
  id bigserial primary key,
  chapter_title text,
  chapter_num bigint,
  section_title text,
  section_num bigint,
  section_url text,
  chunk_num bigint,
  content text,
  content_length bigint,
  content_tokens bigint,
  embedding vector (1536)
);

create or replace function tns_search (
  query_embedding vector(1536),
  similarity_threshold float,
  match_count int
)
returns table (
  id bigint,
  chapter_title text,
  chapter_num bigint,
  section_title text,
  section_num bigint,
  section_url text,
  chunk_num bigint,
  content text,
  content_length bigint,
  content_tokens bigint,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    tns.id,
    tns.chapter_title,
    tns.chapter_num,
    tns.section_title,
    tns.section_num,
    tns.section_url,
    tns.chunk_num,
    tns.text,
    tns.length,
    tns.tokens,
    1 - (tns.embedding <=> query_embedding) as similarity
  from tns
  where 1 - (tns.embedding <=> query_embedding) > similarity_threshold
  order by tns.embedding <=> query_embedding
  limit match_count;
end;
$$;

create index on tns 
using ivfflat (embedding vector_cosine_ops)
with (lists = 100);