export const COLORS = [
  { name: "gray", hex: "#8E8E93" },
  { name: "green", hex: "#34C759" },
  { name: "purple", hex: "#AF52DE" },
  { name: "blue", hex: "#007AFF" },
  { name: "yellow", hex: "#FFCC00" },
  { name: "red", hex: "#FF3B30" },
  { name: "orange", hex: "#FF9500" },
] as const;

export type ColorName = (typeof COLORS)[number]["name"];

export const COMMANDS: { cmd: string; text: string }[] = [
  { cmd: "foldtint color", text: "Show the current color." },
  {
    cmd: "foldtint color purple",
    text: "Set the color for locked Desktop folders. The command writes the configuration, then scans the Desktop.",
  },
  {
    cmd: "foldtint scan",
    text: "Apply or remove the Locked tag on top-level Desktop folders now. Use scan after a repair. You do not need scan when the watcher is on.",
  },
  {
    cmd: "foldtint on",
    text: "Start the watcher. The command installs a LaunchAgent. A lock then applies the color. An unlock removes the color.",
  },
  {
    cmd: "foldtint off",
    text: "Stop the watcher. The command does not remove current tints. The command does not unlock folders.",
  },
  {
    cmd: "foldtint status",
    text: "Show the color, the Desktop path, the watcher state, and the folder counts.",
  },
  {
    cmd: "foldtint daemon",
    text: "Run the watcher in the current process. The on command starts this process through LaunchAgent. Do not run daemon by hand unless you do a test.",
  },
  {
    cmd: "foldtint uninstall",
    text: "Stop the watcher, remove the LaunchAgent, remove the Locked tag, and delete the configuration. The command does not unlock folders.",
  },
  { cmd: "foldtint --help", text: "Show help." },
];

export const LIMITS = [
  "The tool works on macOS only.",
  "The tool works on top-level Desktop folders only.",
  "The tool does not follow symbolic links.",
  "The tool does not use /, /System, or /Applications.",
  "The tool does not set custom icons.",
  "The tool does not use hex colors.",
];

export const FAQ: { q: string; a: string }[] = [
  {
    q: "Which folders does foldtint change?",
    a: "Top-level folders on the Desktop only. The tool does not change nested folders. The tool does not change files, aliases, apps, or packages.",
  },
  {
    q: "What is the default color?",
    a: "Purple.",
  },
  {
    q: "Can I pass a hex color?",
    a: "No. Valid names are gray, green, purple, blue, yellow, red, and orange. These names are Finder tag colors.",
  },
  {
    q: "Does foldtint off remove the tint?",
    a: "No. The off command stops the watcher. It does not remove current tints. It does not unlock folders.",
  },
  {
    q: "Does uninstall unlock folders?",
    a: "No. The uninstall command removes the Locked tag from top-level Desktop folders. It does not unlock folders.",
  },
  {
    q: "Do I need scan when the watcher is on?",
    a: "No. Use scan after a repair. You do not need scan when the watcher is on.",
  },
  {
    q: "Does the tool need root or network access?",
    a: "The install puts a native binary on the computer. The tool does not need network access after install. The tool does not need root access.",
  },
  {
    q: "What does status show?",
    a: "The color, the Desktop path, the watcher state, and the folder counts.",
  },
  {
    q: "Should I run daemon myself?",
    a: "Do not run daemon by hand unless you do a test. The on command starts that process through LaunchAgent.",
  },
];

export const NAV = [
  { href: "#demo", label: "Demo" },
  { href: "#colors", label: "Color" },
  { href: "#install", label: "Install" },
  { href: "#commands", label: "Commands" },
  { href: "#how", label: "How" },
  { href: "#limits", label: "Limits" },
  { href: "#uninstall", label: "Uninstall" },
  { href: "#faq", label: "FAQ" },
];

export const GITHUB = "https://github.com/md786-dotcom/foldtint";
export const NPM = "https://www.npmjs.com/package/foldtint";
export const X = "https://x.com/mdafanulh";
export const INSTALL = "npm install -g foldtint";
