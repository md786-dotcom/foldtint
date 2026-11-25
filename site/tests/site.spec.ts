import { expect, test } from "@playwright/test";

const viewports = [
  { width: 320, height: 700 },
  { width: 375, height: 812 },
  { width: 768, height: 1024 },
  { width: 900, height: 900 },
  { width: 1440, height: 900 },
  { width: 1920, height: 1080 },
];

const shots = new Set([375, 768, 1440]);

for (const viewport of viewports) {
  test(`page at ${viewport.width}x${viewport.height}`, async ({ page }) => {
    test.setTimeout(45000);
    await page.setViewportSize(viewport);
    await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.route("https://api.npmjs.org/downloads/**", (route) =>
      route.fulfill({ json: { downloads: 1234, package: "foldtint" } }),
    );
    await page.goto("/");
    await expect(page.getByTestId("npm-downloads")).toHaveText("1,234");

    const menuButton = page.getByRole("button", { name: /^(Menu|Close)$/ });
    const mobile = viewport.width < 900;

    if (shots.has(viewport.width)) {
      await page.screenshot({
        path: `/opt/cursor/artifacts/foldtint-${viewport.width}.png`,
      });
    }

    if (mobile) {
      await expect(menuButton).toBeVisible();
      await expect(menuButton).toHaveAttribute("aria-expanded", "false");
      await menuButton.click();
      await expect(menuButton).toHaveAttribute("aria-expanded", "true");
      await expect(page.locator("#site-menu")).toBeVisible();
      if (viewport.width === 375) {
        await page.screenshot({
          path: "/opt/cursor/artifacts/foldtint-375-menu.png",
        });
      }
      await page.keyboard.press("Escape");
      await expect(menuButton).toHaveAttribute("aria-expanded", "false");
      await expect(page.locator("#site-menu")).toBeHidden();
      await expect(menuButton).toBeFocused();
    } else {
      await expect(menuButton).toBeHidden();
      await expect(page.locator("#site-menu")).toBeVisible();
    }

    const headerHeight = await page
      .locator("header")
      .evaluate((el) => el.getBoundingClientRect().height);
    expect(headerHeight).toBeLessThanOrEqual(56);
    const markBox = await page.locator(".brand-mark").boundingBox();
    expect(markBox).not.toBeNull();
    expect(markBox!.height).toBeGreaterThanOrEqual(26);
    expect(markBox!.height).toBeLessThanOrEqual(36);

    const brandBox = await page.locator(".brand").boundingBox();
    const tailBox = await page
      .locator(mobile ? ".menu-btn" : "a.nav-install")
      .boundingBox();
    expect(brandBox).not.toBeNull();
    expect(tailBox).not.toBeNull();
    expect(
      Math.abs(
        brandBox!.y + brandBox!.height / 2 - (tailBox!.y + tailBox!.height / 2),
      ),
    ).toBeLessThan(8);

    if (!mobile) {
      const mids = await page.locator("#site-menu a").evaluateAll((els) =>
        els.map((el) => {
          const rect = el.getBoundingClientRect();
          return rect.top + rect.height / 2;
        }),
      );
      expect(Math.max(...mids) - Math.min(...mids)).toBeLessThan(2);
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
      const visible = page.locator(`header a[href="${href}"]`).filter({ visible: true });
      if ((await visible.count()) === 0) await menuButton.click();
      await page.locator(`header a[href="${href}"]`).filter({ visible: true }).first().click();
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

    await expect(
      page.locator(`a[href="https://github.com/md786-dotcom/foldtint"]`).filter({ visible: true }).first(),
    ).toBeVisible();
    await expect(page.locator(`a[href="https://www.npmjs.com/package/foldtint"]`).first()).toBeVisible();
    await expect(page.locator(`a[href="https://x.com/mdafanulh"]`).first()).toBeVisible();

    const still = await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    );
    expect(still).toBe(true);
  });
}

test("header crops at 2x", async ({ browser }) => {
  for (const width of [375, 1440]) {
    const context = await browser.newContext({
      viewport: { width, height: 240 },
      deviceScaleFactor: 2,
    });
    const page = await context.newPage();
    await page.goto("/");
    await page.locator("header").screenshot({
      path: `/opt/cursor/artifacts/header-${width}-2x.png`,
    });
    await context.close();
  }
});
