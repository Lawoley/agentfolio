# DRAFT — updated project description (DO NOT PUBLISH until deployment)

Status: draft for the submission-form edit. The AgentSeal contract address is a
placeholder until the deployment step lands; the form edit must happen before
the edit window closes (Sun 29 Nov 2026, 17:59 WAT).

---

## Q2 / Q6 — Project description (briefly describe your project, its purpose and features)

AgentFolio is the public record for SPACE ID Agent ID holders on BNB Chain.
An Agent ID proves who an agent is. AgentFolio proves what it did — and, with
AgentSeal, what it stands behind.

AgentSeal is the core: any Agent ID holder can sign a public statement with
their name.ai — an offer, a commitment, an authorship claim. The statement's
fingerprint (keccak256 of its exact text) is anchored on-chain in a small
holder-gated contract, under the sealer's own name. Only holders can seal,
and only under a name they actually own: the contract checks both facts
against the official Agent ID registry before recording anything. Anyone can
then verify a statement — recompute its fingerprint and read back who sealed
it, under which name, and when — and a seal can be revoked only by its
author, staying visible as revoked so a check never silently changes its
answer. Because an Agent ID is non-transferable and one per person, a seal
carries weight no ordinary wallet signature can: it is a name that cannot be
faked, standing behind words anyone can check.

Around that core, AgentFolio remains the opt-in public record it launched
with: holders publish a folio, check in daily to prove the identity is
active, and endorse each other, forming a Sybil-resistant reputation graph.
Any contract or app can ask one question in a single read — is this address a
genuine, active, endorsed Agent ID holder? Both contracts are live on BNB
Chain, hold no funds, have no owner or admin functions, and can never move
user assets. AgentFolio never looks up the wallet behind a name that has not
joined: members present themselves, and seals exist only for statements their
authors chose to publish.

## Q5 — Agent ID usage (short form, if the field wants the concise version)

AgentSeal's core flow is gated on-chain by Agent ID: sealing requires
registry.balanceOf(caller) > 0 AND registry.ownerOf(keccak256(name)) ==
caller, so a statement can only ever be sealed by the true owner of the
name it stands under. Verification resolves the seal back to that name.
AgentFolio's folios, check-ins and endorsements are likewise holder-gated,
with the displayed handle read live from the registry.

---

## Form-edit checklist (for whoever runs the edit — before 29 Nov 17:59 WAT)

- **Q2 and Q6 (project description):** replace with the description above.
- **Q3 (contract addresses, descriptive field):** add a line:
  `AgentSeal contract: https://bscscan.com/address/<AGENTSEAL_ADDRESS>`
- **Q9 (BNB Chain contract addresses):** add a line:
  `AgentSeal: <AGENTSEAL_ADDRESS>`
- **Q10 (BscScan verification links):** add:
  `https://bscscan.com/address/<AGENTSEAL_ADDRESS>`
- **Q18 (reward receiving address):** DO NOT TOUCH — must still read
  0xF1A3D84BFB36D8fe3F3C6460147161133Cc6cD62 after the edit. Verify before saving.
- **Q4 (Agent ID):** currently reads "aaron.bnb" — correct to "giuseppino.ai"
  in the same session if that is the name to be judged under.
- **Q12 (demo video):** Joseph's supply item — replace the website link
  currently standing in this field with the real demo video link once recorded.
- After saving: re-open Edit Response and confirm all three contract
  addresses persist and Q18 is unchanged.
