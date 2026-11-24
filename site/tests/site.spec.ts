import { expect, test } from "@playwright/test";

const viewports = [
  { width: 320, height: 700 },
  { width: 375, height: 812 },
  { width: 768, height: 1024 },
  { width: 1440, height: 900 },
  { width: 1920, height: 1080 },
];

const shots = new Set([375, 768, 1440]);

for (const viewport of viewports) {
  test(`page at ${viewport.width}x${viewport.height}`, async ({ page }) => {
    test.setTimeout(45000);
    await page.setViewportSize(viewport);
    await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.goto("/");

    if (shots.has(viewport.width)) {
      await page.screenshot({
        path: `/opt/cursor/artifacts/foldtint-${viewport.width}.png`,
        fullPage: true,
      });
    }

    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    );
    expect(overflow).toBe(true);

    const background = await page.evaluate(
      () => getComputedStyle(document.body).backgroundColor,
    );
    expect(background).toBe("rgb(255, 255, 255)");

    const hrefs = await page.locator("header a[href^='#']").evaluateAll((els) => [
      ...new Set(els.map((el) => el.getAttribute("href"))),
    ]);
    expect(hrefs.length).toBeGreaterThan(0);
    for (const href of hrefs) {
      const id = href!.slice(1);
      const target = page.locator(`#${id}`);
      await expect(target).toHaveCount(1);
      await page.locator(`header a[href="${href}"]`).click();
      await expect
        .poll(async () =>
          target.evaluate((el) => {
            const rect = el.getBoundingClientRect();
            return rect.top < window.innerHeight && rect.bottom > 0;
          }),
        )
        .toBe(true);
    }

    await page.locator(".skip").focus();
    await page.keyboard.press("Enter");
    await expect
      .poll(async () =>
        page.locator("#content").evaluate((el) => {
          const rect = el.getBoundingClientRect();
          return rect.top < window.innerHeight && rect.bottom > 0;
        }),
      )
      .toBe(true);

    await page.getByTestId("copy-install").click();
    await expect(page.getByTestId("copy-install")).toHaveText("Copied");
    const copied = await page.evaluate(() => navigator.clipboard.readText());
    expect(copied).toBe("npm install -g foldtint");

    await expect(page.getByTestId("locked-tag")).toHaveCount(0);
    await page.getByTestId("lock-toggle").click();
    await expect(page.getByTestId("locked-tag")).toBeVisible();
    await expect(page.getByTestId("locked-tag")).toContainText("Locked");
    await page.getByTestId("lock-toggle").click();
    await expect(page.getByTestId("locked-tag")).toHaveCount(0);

    await expect(page.getByTestId("color-command")).toHaveText(
      "foldtint color purple",
    );
    await page.getByTestId("color-red").click();
    await expect(page.getByTestId("color-command")).toHaveText(
      "foldtint color red",
    );
    await expect(page.getByTestId("active-color")).toHaveText("red");

    await expect(page.locator(`a[href="https://github.com/md786-dotcom/foldtint"]`).first()).toBeVisible();
    await expect(page.locator(`a[href="https://www.npmjs.com/package/foldtint"]`).first()).toBeVisible();
    await expect(page.locator(`a[href="https://x.com/mdafanulh"]`).first()).toBeVisible();

    const still = await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    );
    expect(still).toBe(true);
  });
}
