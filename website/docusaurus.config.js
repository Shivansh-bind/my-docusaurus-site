// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import { themes as prismThemes } from 'prism-react-renderer';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'IMPACT Reference Library',
  tagline: 'Where study meets strategy.',
  favicon: 'img/THE_OG.jpg',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://referencelibrary.vercel.app',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'shivansh-bind', // Usually your GitHub org/user name.
  projectName: 'my-docusaurus-site', // Usually your repo name.

  onBrokenLinks: 'throw',

  // onBrokenMarkdownLinks is deprecated, moved to markdown.hooks below

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  // Custom locale data for date formatting with seconds
  customFields: {
    dateFormat: {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    }
  },
  themes: ['@docusaurus/theme-mermaid'],
  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  plugins: [
    [
      '@docusaurus/plugin-content-blog',
      {
        id: 'news',
        path: 'news',
        routeBasePath: 'news',
        blogSidebarTitle: 'News',
        blogSidebarCount: 5,
        onInlineAuthors: 'ignore',
        onUntruncatedBlogPosts: 'ignore',
      },
    ],
  ],


  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Shivansh-bind/my-docusaurus-site/tree/main/website/',
          showLastUpdateTime: true,
          showLastUpdateAuthor: true,
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Shivansh-bind/my-docusaurus-site/tree/main/website/',
          // Useful options to enforce blogging best practices
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Impact Reference Library',
        logo: {
          alt: 'pwfplayz logo',
          src: 'img/THE_OG.jpg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Docs',
          },
          { to: '/news', label: 'News', position: 'left' },
          { to: '/blog', label: 'Blog', position: 'left' },
          { to: '/take-path', label: 'Career Paths', position: 'left' },

          {
            href: 'https://github.com/shivansh-bind',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Orientation',
                to: '/docs/INTRO/',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'Instagram',
                href: 'https://www.instagram.com/pwfplayz_',
              },
              {
                label: 'LinkedIN',
                href: 'https://www.linkedin.com/in/shiwansh-bind-aa5983382/',
              },
              {
                label: 'twitter(X)',
                href: 'https://x.com/shiwansh_bind',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Blog',
                to: '/blog',
              },
              {
                label: 'GitHub',
                href: 'https://github.com/shivansh-bind',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} My Project, Inc. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;
