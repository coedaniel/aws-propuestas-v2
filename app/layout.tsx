import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AWS Propuestas v2 - Sistema Profesional de Propuestas AWS",
  description: "Sistema profesional para generar propuestas AWS con IA. Modo conversación libre + Arquitecto AWS especializado.",
  keywords: ["AWS", "propuestas", "arquitectura", "Bedrock", "IA", "consultoría"],
  authors: [{ name: "AWS Propuestas Team" }],
  openGraph: {
    title: "AWS Propuestas v2",
    description: "Sistema profesional para generar propuestas AWS con IA",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es" suppressHydrationWarning>
      <body className={inter.className}>
        <div className="min-h-screen bg-background">
          {children}
        </div>
      </body>
    </html>
  );
}
