# Contributing to FindMeAFlat

Thank you for your interest in contributing to FindMeAFlat! This document outlines the guidelines and best practices for contributing to this project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Testing](#testing)
- [Adding New Sources](#adding-new-sources)
- [Reporting Issues](#reporting-issues)

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/findmeaflat.git`
3. Add the original repository as upstream: `git remote add upstream https://github.com/xu-chris/findmeaflat.git`
4. Create a feature branch: `git checkout -b feat/your-feature-name`

## Development Setup

### Prerequisites

- Node.js 14 or higher
- Docker (for containerized development)
- Git

### Local Development

```bash
# Install dependencies
npm install

# Copy configuration template
cp conf/config.json.example conf/config.json

# Edit configuration with your settings
# Add your Telegram bot token and chat ID

# Run the application
npm start

# Or with Docker
docker-compose up --build
```

### Environment Setup

```bash
# Set up git commit message template
git config commit.template .gitmessage

# Configure your git settings
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

## Commit Message Guidelines

We strictly follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification for all commit messages.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types (Conventional Commits v1.0.0)

The commit type MUST be one of the following:

- **feat**: A new feature (correlates with MINOR in Semantic Versioning)
- **fix**: A bug fix (correlates with PATCH in Semantic Versioning)
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **docs**: Documentation only changes
- **perf**: A code change that improves performance
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- **test**: Adding missing tests or correcting existing tests

**Note**: According to Conventional Commits v1.0.0, types other than `feat` and `fix` are allowed but not specified in the convention. We use the above types as they are widely adopted.

### Scopes (Optional but Recommended)

Use these scopes to indicate what part of the codebase your change affects:

- **deps**: Dependency updates (use with `build` type)
- **api**: Changes to API interface
- **scraper**: Core scraping functionality
- **sources**: Data source implementations (immoscout, kleinanzeigen, etc.)
- **logger**: Logging system
- **notify**: Notification system
- **config**: Configuration changes
- **utils**: Utility functions
- **store**: Data storage functionality

### Examples (Conventional Commits v1.0.0)

```bash
# New feature (MINOR version bump)
feat(sources): add support for wg-gesucht scraping

# Bug fix (PATCH version bump)
fix(scraper): handle timeout errors gracefully

# Build system changes
build(deps): bump winston from 3.8.0 to 3.17.0

# CI/CD changes
ci: add automated security scanning

# Documentation
docs: update README with new installation steps

# Performance improvement
perf(scraper): improve memory usage in data processing

# Code refactoring
refactor(sources): extract URL parsing to utility function

# Breaking change (MAJOR version bump)
feat!: remove support for Node.js 12

BREAKING CHANGE: Node.js 12 is no longer supported. Minimum required version is now 14.
```

### Breaking Changes (MUST Follow v1.0.0 Spec)

Breaking changes MUST be indicated in two ways:

1. **Add `!` after the type/scope**: `feat!:` or `fix(api)!:`
2. **Include `BREAKING CHANGE:` footer**: Describes the breaking change

```
feat(config)!: remove deprecated scrapeInterval option

BREAKING CHANGE: The `scrapeInterval` configuration option has been removed. Use `intervalInMinutes` instead.
```

**Important**: A BREAKING CHANGE can be part of commits of any type (e.g., `fix!:`, `chore!:`, etc.)

## Pull Request Process

1. **Update your branch** with the latest changes from upstream:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes** thoroughly:
   ```bash
   npm test
   docker-compose up --build  # Test in Docker environment
   ```

3. **Create a pull request** with:
   - Clear title following semantic commit format
   - Detailed description of changes
   - Screenshots/logs if applicable
   - Reference to related issues

4. **PR Requirements**:
   - All tests must pass
   - Security scans must pass
   - At least one reviewer approval
   - Branch must be up-to-date with main

## Code Style

### JavaScript Style Guide

- Use ES6+ features where appropriate
- Prefer `const` over `let`, avoid `var`
- Use meaningful variable and function names
- Keep functions small and focused
- Add JSDoc comments for complex functions

### File Organization

```
lib/
├── sources/          # Data source implementations
├── utils.js         # Utility functions
├── logger.js        # Logging configuration
├── notify.js        # Notification system
├── scraper.js       # Core scraping logic
└── store.js         # Data storage
```

### Naming Conventions

- **Files**: Use kebab-case (`my-file.js`)
- **Functions**: Use camelCase (`myFunction`)
- **Classes**: Use PascalCase (`MyClass`)
- **Constants**: Use UPPER_SNAKE_CASE (`MY_CONSTANT`)

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- --grep "test description"

# Run with coverage
npm run test:coverage
```

### Writing Tests

- Place tests in `test/` directory
- Use descriptive test names
- Test both success and error cases
- Mock external dependencies

Example test structure:
```javascript
describe('FlatFinder', () => {
  describe('normalize()', () => {
    it('should extract price correctly', () => {
      // Test implementation
    })
    
    it('should handle missing data gracefully', () => {
      // Test implementation
    })
  })
})
```

## Adding New Sources

When adding a new flat listing source:

1. **Create source file**: `lib/sources/new-source.js`
2. **Follow existing patterns**: Use `immoscout.js` as a template
3. **Add configuration**: Update `conf/config.json.example`
4. **Test thoroughly**: Ensure scraping works correctly
5. **Add documentation**: Update README with new source info

### Source Implementation Template

```javascript
const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
  // Transform scraped data to standard format
  return {
    id: o.id,
    title: o.title,
    price: o.price + ' €',
    size: o.size + ' m²',
    address: o.address,
    link: o.link,
    rooms: o.rooms
  }
}

function applyBlacklist(o) {
  return !utils.isOneOf(o.title, config.blacklist)
}

const enabled = !!config.providers.newSource

const newSource = {
  name: 'newSource',
  enabled,
  url: !enabled || config.providers.newSource.url,
  crawlContainer: '.listing',
  crawlFields: {
    id: '.listing-id',
    title: '.listing-title',
    price: '.listing-price',
    // ... other fields
  },
  paginate: '.next-page@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(newSource)
```

**Commit message for adding a new source:**
```
feat(sources): add newSource scraping support

Add implementation for newSource apartment listings with:
- Normalized data extraction
- Blacklist filtering
- Pagination support

Closes #123
```

## Reporting Issues

### Bug Reports

When reporting bugs, include:

- **Environment**: OS, Node.js version, Docker version
- **Steps to reproduce**: Clear, numbered steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Logs**: Relevant log output (sanitize sensitive data)
- **Configuration**: Relevant config (remove secrets)

### Feature Requests

For feature requests, include:

- **Problem**: What problem does this solve?
- **Solution**: Proposed solution
- **Alternatives**: Other solutions considered
- **Use case**: Real-world scenario

## Security

- **Never commit secrets**: API keys, tokens, passwords
- **Report security issues privately**: Email maintainer directly
- **Follow security best practices**: Use environment variables for secrets

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

- Open an issue for general questions
- Check existing issues and PRs first
- Join discussions in issue comments

Thank you for contributing to FindMeAFlat! 🏠✨