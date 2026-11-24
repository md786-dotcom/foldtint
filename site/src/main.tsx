import { createRoot, hydrateRoot } from "react-dom/client";
import { App } from "./App";
import "./index.css";

const root = document.getElementById("root");
if (!root) {
  throw new Error("Missing root");
}

const app = <App />;
if (root.childNodes.length > 0) {
  hydrateRoot(root, app);
} else {
  createRoot(root).render(app);
}
