import { useEffect, useRef, useState, type KeyboardEvent, type MouseEvent } from "react";
import {
  COLORS,
  COMMANDS,
  FAQ,
  GITHUB,
  INSTALL,
  LIMITS,
  NAV,
  NPM,
  X,
  type ColorName,
} from "./content";
import { MARK_HTML } from "./logo-ascii";

const FOLDERS: { name: string; kind: "toggle" | "locked" | "open" }[] = [
  { name: "Archive", kind: "toggle" },
  { name: "Taxes", kind: "locked" },
  { name: "Photos", kind: "open" },
  { name: "Notes", kind: "open" },
];

export function App() {
  const [color, setColor] = useState<ColorName>("purple");
  const [locked, setLocked] = useState(false);
  const [copied, setCopied] = useState(false);
  const [open, setOpen] = useState(false);
  const [stuck, setStuck] = useState(false);
  const [downloads, setDownloads] = useState<number | null>(null);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const menuBtn = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (!copied) return;
    const id = window.setTimeout(() => setCopied(false), 2000);
    return () => window.clearTimeout(id);
  }, [copied]);

  useEffect(() => {
    const node = sentinelRef.current;
    if (!node) return;
    const observer = new IntersectionObserver(([entry]) => {
      setStuck(!entry.isIntersecting);
    });
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!open) return;
    menuRef.current?.querySelector("a")?.focus();
  }, [open]);

  useEffect(() => {
    // shortcut: the npm API caps a range at 18 months, switch to summing yearly ranges after 2028-03.
    const today = new Date().toISOString().slice(0, 10);
    fetch(`https://api.npmjs.org/downloads/point/2026-09-04:${today}/foldtint`)
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (typeof data?.downloads === "number") setDownloads(data.downloads);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    const wide = window.matchMedia("(min-width: 900px)");
    const onChange = () => {
      if (wide.matches) setOpen(false);
    };
    wide.addEventListener("change", onChange);
    return () => wide.removeEventListener("change", onChange);
  }, []);

  function onHeaderKeyDown(event: KeyboardEvent<HTMLElement>) {
    if (event.key !== "Escape" || !open) return;
    setOpen(false);
    menuBtn.current?.focus();
  }

  function onMenuClick(event: MouseEvent<HTMLElement>) {
    const link = (event.target as HTMLElement).closest("a");
    if (!link) return;
    setOpen(false);
    const href = link.getAttribute("href") ?? "";
    if (!href.startsWith("#")) return;
    const target = document.getElementById(href.slice(1));
    if (!target) return;
    target.tabIndex = -1;
    target.focus({ preventScroll: true });
  }

  async function copyInstall() {
    await navigator.clipboard.writeText(INSTALL);
    setCopied(true);
  }

  return (
    <>
      <a className="skip" href="#content">
        Skip to content
      </a>
      <div className="sentinel" ref={sentinelRef} aria-hidden="true" />
      <header
        className={stuck ? "is-stuck" : undefined}
        data-open={open ? "" : undefined}
        onKeyDown={onHeaderKeyDown}
      >
        <div className="wrap bar">
          <a className="brand" href="#top" aria-label="foldtint">
            <span
              className="brand-mark"
              aria-hidden="true"
              dangerouslySetInnerHTML={{ __html: MARK_HTML }}
            />
            foldtint
          </a>
          <button
            ref={menuBtn}
            type="button"
            className="menu-btn"
            aria-expanded={open}
            aria-controls="site-menu"
            onClick={() => setOpen((value) => !value)}
          >
            {open ? "Close" : "Menu"}
          </button>
          <nav
            id="site-menu"
            ref={menuRef}
            aria-label="On this page"
            onClick={onMenuClick}
          >
            {NAV.map((item) => (
              <a key={item.href} href={item.href}>
                {item.label}
              </a>
            ))}
            <a className="nav-github" href={GITHUB}>
              GitHub
            </a>
            <a className="nav-install" href="#install">
              Install
            </a>
          </nav>
        </div>
      </header>
      <main id="content">
        <section className="hero" id="top">
          <div className="wrap">
            <p className="eyebrow">
              <span className="eyebrow-dot" aria-hidden="true" />
              macOS CLI · Open source · MIT
            </p>
            <h1>Tint locked Desktop folders.</h1>
            <p className="lede">
              foldtint applies color to locked folders on the Desktop to
              differentiate them from unlocked ones on macOS. Unlocked folders
              keep the default macOS folder color.
            </p>
            <div className="cmdbar">
              <span className="prompt" aria-hidden="true">
                $
              </span>
              <code>{INSTALL}</code>
              <button
                type="button"
                data-testid="copy-install"
                onClick={copyInstall}
                aria-label="Copy install command"
                aria-live="polite"
              >
                {copied ? "Copied" : "Copy"}
              </button>
            </div>
            <div className="hero-actions">
              <a className="btn-primary" href={GITHUB}>
                View on GitHub
              </a>
              <a className="btn-ghost" href={NPM}>
                npm
              </a>
            </div>
            <a className="stat-card" href={NPM}>
              <span className="stat-label">Downloads on npm</span>
              <span className="stat-value" data-testid="npm-downloads">
                {downloads === null ? "—" : downloads.toLocaleString("en-US")}
              </span>
              <span className="stat-note">Since the first release in September 2026</span>
            </a>
            <p className="links">
              <a href={X}>
                <svg viewBox="0 0 16 16" aria-hidden="true">
                  <path
                    fill="currentColor"
                    d="M9.3 6.77 14.7.5h-1.28L8.73 5.95 4.9.5H.5l5.66 8.24L.5 15.5h1.28l4.95-5.76 3.95 5.76h4.4L9.3 6.77zm-1.75 2.04-.57-.82L2.24 1.47h1.96l3.68 5.27.57.82 4.78 6.84h-1.96l-3.9-5.59z"
                  />
                </svg>
                X (@mdafanulh)
              </a>
            </p>
            <p className="meta">
              <span>macOS 14 or later</span>
              <span>Node.js 18 or later</span>
              <span>npm</span>
              <span>MIT License</span>
            </p>
          </div>
        </section>

        <section id="demo" aria-labelledby="demo-title">
          <div className="wrap">
            <h2 id="demo-title">
              <span className="idx" aria-hidden="true">01</span>
              Desktop preview
            </h2>
            <p className="lede">
              A lock on a top-level Desktop folder applies the Locked tag. An
              unlock removes that tag. This preview does not change your Mac.
            </p>
            <div className="desk" data-testid="desktop">
              <div className="desk-bar">
                <span className="lights" aria-hidden="true">
                  <i />
                  <i />
                  <i />
                </span>
                <span className="desk-title">Desktop</span>
                <span className="desk-color" data-testid="active-color">
                  {color}
                </span>
              </div>
              <ul className="folders">
                {FOLDERS.map((folder) => {
                  const isLocked =
                    folder.kind === "locked" ||
                    (folder.kind === "toggle" && locked);
                  return (
                    <li key={folder.name}>
                      <div
                        className={
                          isLocked
                            ? `folder is-locked tint-${color}`
                            : "folder"
                        }
                      >
                        <span className="tab" />
                        <span className="body" />
                      </div>
                      <span className="fname">{folder.name}</span>
                      <span className="tag-slot">
                        {isLocked ? (
                          <span
                            className={`tag tint-${color}`}
                            data-testid={
                              folder.kind === "toggle" ? "locked-tag" : undefined
                            }
                          >
                            <span className="dot" aria-hidden="true" />
                            Locked
                          </span>
                        ) : null}
                      </span>
                    </li>
                  );
                })}
              </ul>
            </div>
            <div className="control">
              <button
                type="button"
                data-testid="lock-toggle"
                aria-pressed={locked}
                onClick={() => setLocked((value) => !value)}
              >
                {locked ? "Unlock Archive" : "Lock Archive"}
              </button>
              <p>
                Lock applies the Finder tag Locked in the selected color.
                Unlock removes only that tag. Other tags stay.
              </p>
            </div>
          </div>
        </section>

        <section id="colors" aria-labelledby="colors-title">
          <div className="wrap">
            <h2 id="colors-title">
              <span className="idx" aria-hidden="true">02</span>
              Color
            </h2>
            <p className="lede">
              Valid names are gray, green, purple, blue, yellow, red, and
              orange. Purple is the default. These names are Finder tag colors.
              Hex values are not valid.
            </p>
            <div className="swatches" role="radiogroup" aria-label="Finder tag color">
              {COLORS.map((item) => (
                <button
                  key={item.name}
                  type="button"
                  role="radio"
                  aria-checked={color === item.name}
                  data-testid={`color-${item.name}`}
                  className={color === item.name ? "swatch is-on" : "swatch"}
                  onClick={() => setColor(item.name)}
                >
                  <span className={`dot tint-${item.name}`} aria-hidden="true" />
                  {item.name}
                </button>
              ))}
            </div>
            <p className="livecmd">
              <code data-testid="color-command">foldtint color {color}</code>
            </p>
            <p className="note">
              <code>foldtint color</code> shows the current color.{" "}
              <code>foldtint color {color}</code> writes the configuration, then
              scans the Desktop.
            </p>
          </div>
        </section>

        <section id="install" aria-labelledby="install-title">
          <div className="wrap prose">
            <h2 id="install-title">
              <span className="idx" aria-hidden="true">03</span>
              Install
            </h2>
            <ol className="steps">
              <li>Open a terminal.</li>
              <li>
                Run <code>{INSTALL}</code>.
              </li>
              <li>
                Run <code>foldtint on</code>.
              </li>
            </ol>
            <p>
              The <code>on</code> command installs a LaunchAgent. The
              LaunchAgent uses the installed <code>foldtint</code> binary. Keep
              the npm global install in place while the watcher runs.
            </p>
            <p>
              Show help with <code>foldtint --help</code>.
            </p>
            <p>
              The install puts a native binary on the computer. The tool does
              not need network access after install. The tool does not need
              root access.
            </p>
          </div>
        </section>

        <section id="commands" aria-labelledby="commands-title">
          <div className="wrap">
            <h2 id="commands-title">
              <span className="idx" aria-hidden="true">04</span>
              Commands
            </h2>
            <div className="rows">
              {COMMANDS.map((item) => (
                <div className="row" key={item.cmd}>
                  <code>{item.cmd}</code>
                  <p>{item.text}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section id="how" aria-labelledby="how-title">
          <div className="wrap prose">
            <h2 id="how-title">
              <span className="idx" aria-hidden="true">05</span>
              How it works
            </h2>
            <ol className="flow">
              <li>
                <h3>Locked flag</h3>
                <p>
                  A locked folder has the Finder Locked checkbox. That flag is
                  the user immutable flag.
                </p>
              </li>
              <li>
                <h3>Locked tag</h3>
                <p>
                  When a folder is locked, foldtint adds the Finder tag Locked
                  with the configured color. Other tags stay.
                </p>
              </li>
              <li>
                <h3>Unlock</h3>
                <p>
                  When a folder is unlocked, foldtint removes only the Locked
                  tag. Other tags stay.
                </p>
              </li>
              <li>
                <h3>Watcher</h3>
                <p>
                  The <code>on</code> command installs a LaunchAgent. The
                  watcher uses directory events on the Desktop. The watcher
                  does not use per-file events. Memory use stays low. When the
                  watcher is on, the tint persists after shutdown and restart.
                </p>
              </li>
            </ol>
          </div>
        </section>

        <section id="limits" aria-labelledby="limits-title">
          <div className="wrap prose">
            <h2 id="limits-title">
              <span className="idx" aria-hidden="true">06</span>
              Limits
            </h2>
            <p>
              foldtint watches top-level folders in ~/Desktop. It does not
              change nested folders, files, aliases, apps, or packages.
            </p>
            <ul className="limits">
              {LIMITS.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        </section>

        <section id="uninstall" aria-labelledby="uninstall-title">
          <div className="wrap prose">
            <h2 id="uninstall-title">
              <span className="idx" aria-hidden="true">07</span>
              Uninstall
            </h2>
            <ol className="steps">
              <li>
                Run <code>foldtint uninstall</code>. The command stops the
                watcher. The command removes the LaunchAgent. The command
                removes the Locked tag from top-level Desktop folders. The
                command deletes the configuration file. The command does not
                unlock folders.
              </li>
              <li>
                Run <code>npm uninstall -g foldtint</code>.
              </li>
            </ol>
          </div>
        </section>

        <section id="faq" aria-labelledby="faq-title">
          <div className="wrap prose">
            <h2 id="faq-title">
              <span className="idx" aria-hidden="true">08</span>
              FAQ
            </h2>
            <div className="faq">
              {FAQ.map((item) => (
                <details key={item.q}>
                  <summary>{item.q}</summary>
                  <p>{item.a}</p>
                </details>
              ))}
            </div>
          </div>
        </section>
      </main>
      <footer>
        <div className="wrap foot">
          <p>
            <a href={`${GITHUB}/blob/main/LICENSE`}>MIT License</a>. Copyright
            2026 Md.
          </p>
          <ul>
            <li>
              <a href={GITHUB}>GitHub</a>
            </li>
            <li>
              <a href={NPM}>npm</a>
            </li>
            <li>
              <a href={X}>X (@mdafanulh)</a>
            </li>
          </ul>
        </div>
      </footer>
    </>
  );
}
