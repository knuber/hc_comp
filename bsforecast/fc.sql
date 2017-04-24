--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fc; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA fc;


ALTER SCHEMA fc OWNER TO postgres;

SET search_path = fc, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: chan; Type: TABLE; Schema: fc; Owner: ptrowbridge
--

CREATE TABLE chan (
    reason text,
    party text,
    frequency interval,
    fcst_basis text
);


ALTER TABLE chan OWNER TO ptrowbridge;

--
-- Name: TABLE chan; Type: COMMENT; Schema: fc; Owner: ptrowbridge
--

COMMENT ON TABLE chan IS 'forecast channels and associated frequency and basis for forecasting';


--
-- Name: dble; Type: TABLE; Schema: fc; Owner: postgres
--

CREATE TABLE dble (
    flow text,
    party text,
    event text,
    flag text,
    account text,
    sign integer,
    vers text
);


ALTER TABLE dble OWNER TO postgres;

--
-- Name: TABLE dble; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON TABLE dble IS 'event account assignment';


--
-- Name: COLUMN dble.flow; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.flow IS 'work flow';


--
-- Name: COLUMN dble.party; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.party IS 'party';


--
-- Name: COLUMN dble.event; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.event IS 'work flow event';


--
-- Name: COLUMN dble.flag; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.flag IS 'debit credit row creator';


--
-- Name: COLUMN dble.account; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.account IS 'gl account';


--
-- Name: COLUMN dble.sign; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.sign IS 'sign to apply to base number';


--
-- Name: COLUMN dble.vers; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN dble.vers IS 'forecast version';


--
-- Name: evnt; Type: TABLE; Schema: fc; Owner: postgres
--

CREATE TABLE evnt (
    flow text,
    driver text,
    factor numeric,
    vers text
);


ALTER TABLE evnt OWNER TO postgres;

--
-- Name: TABLE evnt; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON TABLE evnt IS 'forecasted work flows';


--
-- Name: COLUMN evnt.flow; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN evnt.flow IS 'work flow';


--
-- Name: COLUMN evnt.driver; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN evnt.driver IS 'driver';


--
-- Name: COLUMN evnt.factor; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN evnt.factor IS 'number to multiply by to get forecast of related item';


--
-- Name: COLUMN evnt.vers; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN evnt.vers IS 'forecast version';


--
-- Name: fcst; Type: TABLE; Schema: fc; Owner: postgres
--

CREATE TABLE fcst (
    driver text,
    perd tsrange,
    amount numeric,
    vers text
);


ALTER TABLE fcst OWNER TO postgres;

--
-- Name: TABLE fcst; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON TABLE fcst IS 'forecast drivers';


--
-- Name: COLUMN fcst.driver; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN fcst.driver IS 'forecasted driver';


--
-- Name: COLUMN fcst.perd; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN fcst.perd IS 'forecast date range';


--
-- Name: COLUMN fcst.amount; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN fcst.amount IS 'value or amount';


--
-- Name: COLUMN fcst.vers; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON COLUMN fcst.vers IS 'version';


--
-- Name: party; Type: TABLE; Schema: fc; Owner: postgres
--

CREATE TABLE party (
    flow text,
    party text,
    split numeric,
    effr tsrange,
    freq interval,
    vers text
);


ALTER TABLE party OWNER TO postgres;

--
-- Name: TABLE party; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON TABLE party IS 'party share of forecasted flow';


--
-- Name: schd; Type: TABLE; Schema: fc; Owner: postgres
--

CREATE TABLE schd (
    flow text,
    party text,
    event text,
    seq integer,
    duration interval,
    vers text
);


ALTER TABLE schd OWNER TO postgres;

--
-- Name: TABLE schd; Type: COMMENT; Schema: fc; Owner: postgres
--

COMMENT ON TABLE schd IS 'party timing of flow events';


--
-- PostgreSQL database dump complete
--

