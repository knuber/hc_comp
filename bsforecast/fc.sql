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
-- Name: fc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA fc;


SET search_path = fc, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: evnt; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE evnt (
    flow text NOT NULL,
    element text NOT NULL,
    claim numeric,
    loc text NOT NULL,
    vers text NOT NULL
);


--
-- Name: TABLE evnt; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE evnt IS 'element flows';


--
-- Name: COLUMN evnt.flow; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.flow IS 'work flow';


--
-- Name: COLUMN evnt.element; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.element IS 'element';


--
-- Name: COLUMN evnt.claim; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.claim IS 'extent that flow models the forecast element';


--
-- Name: COLUMN evnt.loc; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.loc IS 'location';


--
-- Name: COLUMN evnt.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN evnt.vers IS 'version';


--
-- Name: fcst; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE fcst (
    element text NOT NULL,
    perd tsrange NOT NULL,
    amount numeric,
    loc text NOT NULL,
    vers text NOT NULL
);


--
-- Name: TABLE fcst; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE fcst IS 'forecast drivers';


--
-- Name: COLUMN fcst.element; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.element IS 'element';


--
-- Name: COLUMN fcst.perd; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.perd IS 'date range';


--
-- Name: COLUMN fcst.amount; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.amount IS 'value or amount';


--
-- Name: COLUMN fcst.loc; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.loc IS 'location';


--
-- Name: COLUMN fcst.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN fcst.vers IS 'version';


--
-- Name: party; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE party (
    flow text NOT NULL,
    party text NOT NULL,
    split numeric,
    effr tsrange NOT NULL,
    freq interval,
    schd text,
    loc text NOT NULL,
    vers text NOT NULL
);


--
-- Name: TABLE party; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE party IS 'party share of forecasted flow';


--
-- Name: COLUMN party.flow; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.flow IS 'flow';


--
-- Name: COLUMN party.party; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.party IS 'party';


--
-- Name: COLUMN party.split; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.split IS 'allocation of flow to party';


--
-- Name: COLUMN party.effr; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.effr IS 'effective applicable range';


--
-- Name: COLUMN party.freq; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.freq IS 'frequncy of incur';


--
-- Name: COLUMN party.schd; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN party.schd IS 'event sequence reference';


--
-- Name: patt; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE patt (
    flow text NOT NULL,
    sched text,
    event text NOT NULL,
    account text NOT NULL,
    sign integer,
    factor numeric,
    element text,
    loc text,
    vers text
);


--
-- Name: TABLE patt; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE patt IS 'event account assignment';


--
-- Name: COLUMN patt.flow; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.flow IS 'work flow';


--
-- Name: COLUMN patt.sched; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.sched IS 'schedule';


--
-- Name: COLUMN patt.event; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.event IS 'work flow event';


--
-- Name: COLUMN patt.account; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.account IS 'gl account';


--
-- Name: COLUMN patt.sign; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.sign IS 'sign to apply to base number';


--
-- Name: COLUMN patt.factor; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.factor IS 'element factor';


--
-- Name: COLUMN patt.element; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.element IS 'element';


--
-- Name: COLUMN patt.loc; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.loc IS 'location';


--
-- Name: COLUMN patt.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN patt.vers IS 'version';


--
-- Name: schd; Type: TABLE; Schema: fc; Owner: -
--

CREATE TABLE schd (
    party text NOT NULL,
    sched text NOT NULL,
    event text NOT NULL,
    seq integer,
    duration interval,
    effr tsrange NOT NULL,
    loc text NOT NULL,
    vers text NOT NULL
);


--
-- Name: TABLE schd; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON TABLE schd IS 'party timing of flow events';


--
-- Name: COLUMN schd.party; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.party IS 'flow';


--
-- Name: COLUMN schd.sched; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.sched IS 'schedule';


--
-- Name: COLUMN schd.event; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.event IS 'event';


--
-- Name: COLUMN schd.seq; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.seq IS 'sequence';


--
-- Name: COLUMN schd.duration; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.duration IS 'duration';


--
-- Name: COLUMN schd.effr; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.effr IS 'effective applicable range';


--
-- Name: COLUMN schd.loc; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.loc IS 'locations';


--
-- Name: COLUMN schd.vers; Type: COMMENT; Schema: fc; Owner: -
--

COMMENT ON COLUMN schd.vers IS 'version';


--
-- Name: evnt fc_evnt; Type: CONSTRAINT; Schema: fc; Owner: -
--

ALTER TABLE ONLY evnt
    ADD CONSTRAINT fc_evnt PRIMARY KEY (flow, element, loc, vers);


--
-- Name: party fc_party; Type: CONSTRAINT; Schema: fc; Owner: -
--

ALTER TABLE ONLY party
    ADD CONSTRAINT fc_party PRIMARY KEY (flow, party, effr, loc, vers);


--
-- Name: patt fc_patern; Type: CONSTRAINT; Schema: fc; Owner: -
--

ALTER TABLE ONLY patt
    ADD CONSTRAINT fc_patern PRIMARY KEY (flow, event, account);


--
-- Name: schd fc_schd; Type: CONSTRAINT; Schema: fc; Owner: -
--

ALTER TABLE ONLY schd
    ADD CONSTRAINT fc_schd PRIMARY KEY (party, sched, event, effr, loc, vers);


--
-- Name: fcst fcst_pk; Type: CONSTRAINT; Schema: fc; Owner: -
--

ALTER TABLE ONLY fcst
    ADD CONSTRAINT fcst_pk PRIMARY KEY (element, perd, loc, vers);


--
-- PostgreSQL database dump complete
--

