# Protected A5 governance finalizer fixture

This fixture is a sanitized structural model of the retained 059 terminal
classification. It preserves the public transaction identifier, retained lease
digest, terminal result, terminal failure code, reconciliation result, and
independent-verifier result. It contains no production-local lease bytes,
protected response bodies, credentials, device data, or remote transaction
journal content.

Tests copy the fixture into a fresh temporary task root. The copied synthetic
lease has its own computed digest; a short-lived synthetic Owner authorization
binds that synthetic digest. The retained 059 digest is asserted only as an
immutable incident-model input and is never used as a mutable test target.
