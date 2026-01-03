# Unused / Possibly Unused Library Includes — Quick Scan

This report lists pages that include vendor libraries in `lib/` and whether a quick scan found obvious usage markers (animations, carousels, counters, etc.). This is a conservative, automated pass — please verify each suggestion on a staging server before removing includes.

Scan date: 2025-12-31

## Libraries checked
- lib/wow (wow.min.js)
- lib/easing (easing.min.js)
- lib/waypoints (waypoints.min.js)
- lib/counterup (counterup.min.js)
- lib/owlcarousel (owl.carousel.min.js)

## Pages including libraries (found in HTML)
- index.html — uses carousel/hero images and other markers (KEEP)
- testbed.html — uses WOW/waypoints/owlcarousel (KEEP)
- research.html — uses WOW/waypoints/owlcarousel (KEEP)
- aepc.html — hero images / content (KEEP)
- qrdlab.html — includes libraries (likely used) (VERIFY)
- pcpc.html — includes libraries (used for certification display; minimal) (VERIFY)
- pcp-cai.html — includes libraries (VERIFY)
- pcpc/pcp-cai/aepc pages — include libs; verify per-page features

Potential candidates for review (includes present but no obvious automation/carousel/counter markers found by the quick scan):
- lab-access-form.html — includes libraries but the page is a form; consider removing carousel/WOW includes
- internship-register.html — includes libraries but appears to be a submission form; consider removing animation/carousel libs
- industry-visit-register.html — form page; consider removing animation/carousel libs
- events.html — may require review (some event pages do use animations); verify
- contact.html, career.html — often do not need carousel/waypoints; consider review
- crdlab.html — contains spinner logic and may use WOW; verify before removal

## Recommendation
1. Do not remove libraries globally; remove per-page when not used.
2. For each candidate page above:
   - Load the page locally with `js/main.min.js` disabled to confirm UI/behavior unaffected.
   - If safe, remove the specific `<script src="lib/...">` lines from that page only.
3. After any removal, run a Lighthouse or manual QA pass to ensure nothing broke.

## Next steps I can run for you
- Create a patch to remove `lib/owlcarousel` / `lib/wow` includes from specific pages identified above (I can apply conservative removals, e.g., remove `owlcarousel` from form pages first).
- Run an automated DOM scan (headless) to detect elements specifically referencing these libraries (more accurate; requires Node/python tooling not available in this environment).

If you want, tell me which pages to target first (I suggest starting with `lab-access-form.html`, `internship-register.html`, `industry-visit-register.html`).
