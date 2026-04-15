"use client";

import { useEffect } from "react";
import { initRuntimeI18n } from "./runtime";

/**
 * Client-side i18n: MutationObserver in initRuntimeI18n already picks up new DOM
 * from route transitions. Re-running full-body translation on every pathname change
 * could race React reconciliation and crash the app (Next generic error page).
 */
export function RuntimeI18nProvider({ children }) {
  useEffect(() => {
    initRuntimeI18n().catch(() => {});
  }, []);

  return <>{children}</>;
}
