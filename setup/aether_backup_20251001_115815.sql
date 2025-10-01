--
-- PostgreSQL database dump
--

\restrict jfVQ7PJPzC14vcea5V69a0X0j9JQBAfnepXrN5VCf2mNU9V53YRCr1ZATYz7EOL

-- Dumped from database version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: aether_user
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO aether_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ab_tests; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.ab_tests (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    screen_id integer,
    variant_a jsonb NOT NULL,
    variant_b jsonb NOT NULL,
    traffic_split numeric(3,2) DEFAULT 0.5,
    is_active boolean DEFAULT false,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ab_tests OWNER TO aether_user;

--
-- Name: ab_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.ab_tests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ab_tests_id_seq OWNER TO aether_user;

--
-- Name: ab_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.ab_tests_id_seq OWNED BY public.ab_tests.id;


--
-- Name: analytics_events; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.analytics_events (
    id bigint NOT NULL,
    event_type character varying(50) NOT NULL,
    screen_id integer,
    element_id character varying(100),
    user_id character varying(100),
    session_id character varying(100),
    platform character varying(20),
    properties jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.analytics_events OWNER TO aether_user;

--
-- Name: analytics_events_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.analytics_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analytics_events_id_seq OWNER TO aether_user;

--
-- Name: analytics_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.analytics_events_id_seq OWNED BY public.analytics_events.id;


--
-- Name: screen_versions; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.screen_versions (
    id integer NOT NULL,
    screen_id integer,
    version integer NOT NULL,
    config jsonb NOT NULL,
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.screen_versions OWNER TO aether_user;

--
-- Name: screen_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.screen_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.screen_versions_id_seq OWNER TO aether_user;

--
-- Name: screen_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.screen_versions_id_seq OWNED BY public.screen_versions.id;


--
-- Name: screens; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.screens (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(100) NOT NULL,
    version integer DEFAULT 1,
    config jsonb NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.screens OWNER TO aether_user;

--
-- Name: screens_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.screens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.screens_id_seq OWNER TO aether_user;

--
-- Name: screens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.screens_id_seq OWNED BY public.screens.id;


--
-- Name: templates; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.templates (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    config jsonb NOT NULL,
    is_shared boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.templates OWNER TO aether_user;

--
-- Name: templates_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.templates_id_seq OWNER TO aether_user;

--
-- Name: templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.templates_id_seq OWNED BY public.templates.id;


--
-- Name: ui_components; Type: TABLE; Schema: public; Owner: aether_user
--

CREATE TABLE public.ui_components (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(50) NOT NULL,
    schema jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ui_components OWNER TO aether_user;

--
-- Name: ui_components_id_seq; Type: SEQUENCE; Schema: public; Owner: aether_user
--

CREATE SEQUENCE public.ui_components_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ui_components_id_seq OWNER TO aether_user;

--
-- Name: ui_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aether_user
--

ALTER SEQUENCE public.ui_components_id_seq OWNED BY public.ui_components.id;


--
-- Name: ab_tests id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ab_tests ALTER COLUMN id SET DEFAULT nextval('public.ab_tests_id_seq'::regclass);


--
-- Name: analytics_events id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.analytics_events ALTER COLUMN id SET DEFAULT nextval('public.analytics_events_id_seq'::regclass);


--
-- Name: screen_versions id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screen_versions ALTER COLUMN id SET DEFAULT nextval('public.screen_versions_id_seq'::regclass);


--
-- Name: screens id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screens ALTER COLUMN id SET DEFAULT nextval('public.screens_id_seq'::regclass);


--
-- Name: templates id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.templates ALTER COLUMN id SET DEFAULT nextval('public.templates_id_seq'::regclass);


--
-- Name: ui_components id; Type: DEFAULT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ui_components ALTER COLUMN id SET DEFAULT nextval('public.ui_components_id_seq'::regclass);


--
-- Data for Name: ab_tests; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.ab_tests (id, name, screen_id, variant_a, variant_b, traffic_split, is_active, start_date, end_date, created_at) FROM stdin;
\.


--
-- Data for Name: analytics_events; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.analytics_events (id, event_type, screen_id, element_id, user_id, session_id, platform, properties, created_at) FROM stdin;
\.


--
-- Data for Name: screen_versions; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.screen_versions (id, screen_id, version, config, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: screens; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.screens (id, name, slug, version, config, is_active, created_at, updated_at) FROM stdin;
1	Demo Home Screen	demo-home	1	{"type": "container", "children": [{"id": "welcome_text", "size": "large", "type": "text", "content": "Welcome to THE LAST SIBERIA UI!"}, {"id": "demo_button", "text": "Click me!", "type": "button", "style": "primary", "action": "navigate_to_details"}], "direction": "column"}	t	2025-10-01 11:57:56.497095	2025-10-01 11:57:56.497095
\.


--
-- Data for Name: templates; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.templates (id, name, config, is_shared, created_at) FROM stdin;
\.


--
-- Data for Name: ui_components; Type: TABLE DATA; Schema: public; Owner: aether_user
--

COPY public.ui_components (id, name, type, schema, created_at, updated_at) FROM stdin;
1	button	action	{"type": "object", "properties": {"text": {"type": "string"}, "style": {"enum": ["primary", "secondary"], "type": "string"}, "action": {"type": "string"}}}	2025-10-01 11:57:56.496383	2025-10-01 11:57:56.496383
2	text	display	{"type": "object", "properties": {"size": {"enum": ["small", "medium", "large"], "type": "string"}, "color": {"type": "string"}, "content": {"type": "string"}}}	2025-10-01 11:57:56.496383	2025-10-01 11:57:56.496383
3	image	media	{"type": "object", "properties": {"alt": {"type": "string"}, "url": {"type": "string"}, "width": {"type": "number"}, "height": {"type": "number"}}}	2025-10-01 11:57:56.496383	2025-10-01 11:57:56.496383
4	container	layout	{"type": "object", "properties": {"children": {"type": "array"}, "direction": {"enum": ["row", "column"], "type": "string"}}}	2025-10-01 11:57:56.496383	2025-10-01 11:57:56.496383
\.


--
-- Name: ab_tests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.ab_tests_id_seq', 1, false);


--
-- Name: analytics_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.analytics_events_id_seq', 1, false);


--
-- Name: screen_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.screen_versions_id_seq', 1, false);


--
-- Name: screens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.screens_id_seq', 1, true);


--
-- Name: templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.templates_id_seq', 1, false);


--
-- Name: ui_components_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aether_user
--

SELECT pg_catalog.setval('public.ui_components_id_seq', 4, true);


--
-- Name: ab_tests ab_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ab_tests
    ADD CONSTRAINT ab_tests_pkey PRIMARY KEY (id);


--
-- Name: analytics_events analytics_events_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.analytics_events
    ADD CONSTRAINT analytics_events_pkey PRIMARY KEY (id);


--
-- Name: screen_versions screen_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screen_versions
    ADD CONSTRAINT screen_versions_pkey PRIMARY KEY (id);


--
-- Name: screen_versions screen_versions_screen_id_version_key; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screen_versions
    ADD CONSTRAINT screen_versions_screen_id_version_key UNIQUE (screen_id, version);


--
-- Name: screens screens_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screens
    ADD CONSTRAINT screens_pkey PRIMARY KEY (id);


--
-- Name: screens screens_slug_key; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screens
    ADD CONSTRAINT screens_slug_key UNIQUE (slug);


--
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: ui_components ui_components_name_key; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ui_components
    ADD CONSTRAINT ui_components_name_key UNIQUE (name);


--
-- Name: ui_components ui_components_pkey; Type: CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ui_components
    ADD CONSTRAINT ui_components_pkey PRIMARY KEY (id);


--
-- Name: idx_ab_tests_active; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_ab_tests_active ON public.ab_tests USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_analytics_events_created_at; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_analytics_events_created_at ON public.analytics_events USING btree (created_at);


--
-- Name: idx_analytics_events_screen; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_analytics_events_screen ON public.analytics_events USING btree (screen_id, event_type);


--
-- Name: idx_screens_active; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_screens_active ON public.screens USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_screens_config; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_screens_config ON public.screens USING gin (config);


--
-- Name: idx_screens_slug; Type: INDEX; Schema: public; Owner: aether_user
--

CREATE INDEX idx_screens_slug ON public.screens USING btree (slug);


--
-- Name: screens update_screens_updated_at; Type: TRIGGER; Schema: public; Owner: aether_user
--

CREATE TRIGGER update_screens_updated_at BEFORE UPDATE ON public.screens FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ab_tests ab_tests_screen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.ab_tests
    ADD CONSTRAINT ab_tests_screen_id_fkey FOREIGN KEY (screen_id) REFERENCES public.screens(id);


--
-- Name: analytics_events analytics_events_screen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.analytics_events
    ADD CONSTRAINT analytics_events_screen_id_fkey FOREIGN KEY (screen_id) REFERENCES public.screens(id);


--
-- Name: screen_versions screen_versions_screen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: aether_user
--

ALTER TABLE ONLY public.screen_versions
    ADD CONSTRAINT screen_versions_screen_id_fkey FOREIGN KEY (screen_id) REFERENCES public.screens(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict jfVQ7PJPzC14vcea5V69a0X0j9JQBAfnepXrN5VCf2mNU9V53YRCr1ZATYz7EOL

