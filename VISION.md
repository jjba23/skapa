# Vision

Skapa scaffolds projects from templates whose placeholders are real Scheme
expressions between `ΔΔ` delimiters, so a template can compute a name, choose a
paragraph and fill in a licence rather than merely substituting a variable. That
one decision — the template language is the host language — is the whole idea, and
everything worth building next follows from taking it seriously: templates that
can be tested, a command that can run without a human at the prompt, and a
dialect specified tightly enough that a template remains readable a year later.

## Where Skapa is today

At v0.0.11 the program is 1108 lines in four modules, plus templates and licence
data as resources.

- `(skapa main)` — 122 lines: `getopt-long`, then a wizard that chooses a
  template, asks the template's questions, resolves a licence and renders.
- `(skapa valg)` — 359 lines: the prompt engine. Three prompt types (`string`,
  `choice`, `boolean`), `required?` and `default`, a persistent answer cache at
  `~/.config/skapa/memory.scm`, and `cli-options` filling in answers passed as flags.
- `(skapa engine)` — 520 lines: directory recursion, a table of about two hundred
  binary extensions plus a UTF-8 decoding fallback so that images, jars and
  archives are copied byte for byte, `mkdir-p`, `rm-rf`,
  `list-available-templates`, the `.skapa.scm` project memory, and the `ΔΔ`
  evaluator: the expressions in a token are `read` and `eval`ed in a fresh module
  built from the context, so a template gets the answers as bindings and a boolean
  result becomes `true`/`false`.
- `(skapa license)` — 107 lines: a licence directory holds a `COPYING` or `LICENSE`
  plus any number of `header.<ext>` files, so generated source can carry a header.
- Five templates: `simple-readme`, `cli-guile-scheme-guix`, `kotlin-spring-boot-web`,
  `scala-2-playground`, `zio-http`. They are substantial — the Kotlin one carries a
  Gradle wrapper, lockfiles, a Justfile, a flake and its own tests — which is the
  point: the hard part of starting a project is the boilerplate nobody remembers.

The honest state of the edges:

- **The tool has no tests of its own.** There is no `test/` directory and no spec
  for the evaluator, the binary detection, the memory merge or the prompts, even
  though the repository's own agent practices demand a failing test first.
- **The installed command exposes less than the program does.** The bash wrapper
  forwards `--resources`, `--template` and `--help`; the Guile entry point also
  accepts `--name`, `--creator`, `--type`, `--license` and `--owner`; the help text
  documents all of them plus a `--list` that no option spec mentions. Three
  surfaces, three different answers.
- **One licence body ships.** `resources/licenses/` contains `gpl3` only, while the
  help text's example offers `-l MIT`.
- **`.skapa.scm` remembers answers but nothing re-renders.** The memory merges into
  a later run's context, which is the beginning of an update story and not yet one.

Four decisions constrain what comes next.

1. **Templates are evaluated, not parsed.** `read` and `eval` in a fresh module
   means a template can do anything Scheme can — including fail — and it means the
   template format is the language, with no second syntax to learn or implement.
2. **A template is two things: `contents/` and `valg.scm`.** No manifest, no
   inheritance, no metadata beyond the prompt list and a display name.
3. **Nothing is a template-specific special case.** Path components are rendered as
   well as file contents, so a directory named `ΔΔ project-name ΔΔ` works
   everywhere, and `valg.scm`/`.skapa.scm`/`.DS_Store` are skipped by name.
4. **Memory is a file, not a service.** Answers live in `~/.config/skapa/memory.scm`
   and `./.skapa.scm`, both plain Scheme a person can read and edit.

## The vision

1. **The engine is tested, and the dialect is specified.** The evaluator's contract
   — how a boolean, a list and an error are rendered, what happens in a path
   component, what a token may not contain — is written down and covered by a
   suite, so a template author can predict what their template will do.
2. **One command surface.** The installed wrapper exposes every option the program
   accepts, `--list` exists and prints something a script can read, and every
   interactive question has a flag, so a wizard and a pipeline use the same code.
3. **Templates are tested too.** A template can declare how to check the project it
   produced, and CI scaffolds and builds each shipped template, so "this template
   works" is a build result rather than a claim in a README.
4. **Licences are data with an SPDX name.** Any licence the repository ships can be
   selected by the identifier its family uses, with a body and headers for each
   language the templates emit — so `-l MIT` stops being an example the repository
   cannot honour.
5. **A generated project can be updated.** Re-running Skapa against an existing
   directory reports what would change, keeps the answers already recorded, and
   re-renders only what the template owns — the difference between a scaffolder and
   a generator you are not afraid to run twice.

## Features that are in scope and not built yet

The code already anticipates each of these; the hard part is named.

- **Re-rendering an existing project.** `load-project-memory` and `merge-context`
  exist so a second run reuses the first run's answers, and `rm-rf` sits unused
  because nothing decides what may be replaced. Hard part: telling a file the
  template owns from one the user has since edited — a manifest of rendered
  outputs, or a three-way comparison, and both need the template revision recorded.
- **Language-aware licence headers.** `load-all-license-headers` discovers
  `header.<ext>` files per licence, but only `gpl3` ships any, and no template says
  where a header may go. Hard part: `#`, `//` and XML comments, and files that must
  not be touched at all (JSON), decided per template rather than guessed by suffix.
- **Two licence regimes.** `-t o` versus `-t p` is in the option spec and the help
  text; the difference is a proprietary project carrying no free-software header.
  Hard part: the same rendering path has to produce absence, which a template
  language can get wrong silently.
- **More prompt types.** Three cover the current templates. Hard part: adding a
  multi-choice or a path type without turning `valg.scm` from an alist into a
  schema — the format's readability is its main feature.
- **A machine-readable template catalogue.** `list-available-templates` returns
  names; prompts, defaults and licence are only visible by starting the wizard.
  Hard part: exposing the catalogue without a second source of truth beside
  `valg.scm`.
- **A wrapper generated from the option spec.** Today's wrapper is hand-written and
  has drifted. Hard part: a bash `getopt` string and a Guile `option-spec` that
  cannot disagree, which probably means generating one from the other.

## New features that would be worth having

- **`--defaults`, `--dry-run` and `--set key=value`.** Three small options that
  turn a wizard into a tool: non-interactive generation, a list of what would be
  written, and an answer for any prompt key without a flag per key.
- **`skapa --list --json` and `--show TEMPLATE`.** The catalogue as data — name,
  prompts, types, defaults — which is what shell completion, CI or a documentation
  page needs, and what the project cannot currently produce.
- **Remote templates.** A template is a directory with a `valg.scm`, and nothing
  requires it to live in the distribution: `--template-from` could fetch a git
  repository into a cache, the difference between five templates and fifty.
  Speculative and not yet in scope, and a template is code, so the trust question
  has to be answered in the documentation rather than glossed over.
- **Post-generation hooks in `valg.scm`.** Something like
  `(hooks . (("fmt" "gofmt" "-w" ".")))` would let a template leave a repository
  already formatted and already initialised. Hard part: running commands is a trust
  boundary, and the rule against building a shell string out of data applies.
- **A `skapa` task inside a generated Guile project** so the project can scaffold
  its own sub-projects from the same template — cheap for the Guile templates.
- **Template inheritance.** A base "Guile CLI" template plus a thin "with a
  database" layer is what every scaffolder eventually wants; it is the one idea
  here that would change the template format, and deserves a design before code.

## Contributions that would move the needle

1. **Tests for the engine and the prompts.** Highest value by a wide margin: the
   evaluator's `catch` turns any failure into `[[Template Error …]]` inside the
   output, so a mistake in a template is invisible until someone reads the
   generated file. A suite over `render-template-string`, path rendering, binary
   detection and `merge-context` would make every other item below safer.
2. **Reconcile the command surface.** One wrapper that forwards the whole option
   spec, `--list` implemented, help text and reality agreeing: small, entirely
   user-visible, and today's mismatch makes every other feature harder to describe.
3. **Ship more licence bodies.** MIT, Apache-2.0, BSD-3-Clause and AGPL-3.0 as
   directory data with headers for the languages the templates emit. No code
   changes, and it makes the documented example true.
4. **A template self-test task with CI.** One task per template that scaffolds into
   a temporary directory and runs that stack's build (`gradle test`, `just test`,
   `guix build`), wired into CI as a matrix, so no template bit-rots silently.
5. **`--dry-run` and `--defaults`.** Small and unambiguous, and they make Skapa
   usable in scripts and containers — where an interactive-only tool is excluded.
6. **A manifest of rendered files.** The prerequisite for re-rendering, and the
   piece that lets later work be a diff rather than an overwrite.

## Compared to related projects

| Project | What it is | Where Skapa differs |
|---------|------------|----------------------|
| cookiecutter | the widely used Python scaffolder: a `cookiecutter.json` of variables, Jinja2 templates, hooks, and a large community template index | Jinja2 gives conditionals inside a file; Skapa gives the whole host language in any position, including path names, and reads its answers from a Scheme alist rather than a JSON spec |
| copier | a Python scaffolder with Jinja templates, a questions file and, crucially, the ability to update a project from a newer template version | copier is the model for the update story Skapa lacks; Skapa's advantage is one dependency-free implementation instead of a Python environment |
| cargo-generate | Rust's template-driven project generator, with Liquid templates, conditional files and git-based template sources | same shape, different ecosystem; cargo-generate's remote templates and file-level conditionals are features Skapa wants and does not have |
| `nix flake init -t` and Guix | template registries where a template is a directory that is copied and edited | copying is the whole mechanism — no prompts, no computed content — which is why Skapa exists for the projects these tools leave as an exercise |
| Yeoman | a JavaScript generator ecosystem with a generator API, prompts and sub-generators, driven by a runtime | Yeoman treats the generator as a program with escaped templates; Skapa makes the template itself the program, and needs no Node runtime |
| Maven archetypes | XML-described project templates for the JVM, with a catalogue and interactive property prompts | the closest in spirit for the Kotlin and Scala templates, and the clearest example of how verbose a template format can become; Skapa's `valg.scm` is thirty lines where an archetype is a directory of XML |

What the others do that this could still add: copier's and cargo-generate's remote
template sources, copier's update path, and the reach of a template index other
people can contribute to. Where Skapa is ahead and should stay ahead: a template
may compute anything, in a language whose semantics are documented elsewhere; path
names are expressions too, so a package name appears in a directory rather than in
a comment; binary files are copied byte for byte without a rule per file type; and
the whole program is one dependency-free implementation.

## In the long run

- **Templates are the durable artefact.** The tool is small and finished early; the
  value compounds in the templates for stacks that are genuinely hard to bootstrap
  correctly — a Guix channel, a ZIO service, a Kotlin web app with lockfiles. A
  template that is tested on every push is worth more than a hundred that are not.
- **Generation becomes updating.** The most valuable thing a scaffolder can do is
  run again: that needs recorded template revisions, an ownership manifest and a
  merge policy, and it is the feature which turns Skapa from "used once per
  project" into "used whenever the template improves".
- **The dialect stays small.** `ΔΔ` expression `ΔΔ` inside a file or a path name is
  a rule a person can hold in their head. Every future feature — hooks, remote
  templates, inheritance — should be expressible without touching that rule, or it
  is a different language wearing the same delimiters.

## Getting there from here

Write the tests first, because a template language with an invisible error path is
the riskiest thing in the repository. Then reconcile the CLI and ship the missing
licence bodies, both visible and cheap. Then the work that needs design rather than
code: a rendered-file manifest and the re-render path it enables, and only after
that remote templates and hooks, each of which changes what "a template" means.

*This document describes intent, not commitments: the template format, the
licence and the commands that exist today are the contract, and nothing here
alters them.*
