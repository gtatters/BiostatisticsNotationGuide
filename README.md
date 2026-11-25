# Biostatistics Notational Guide

An interactive Shiny app where biology students practise **reading statistical notation and doing the arithmetic it asks for**. It is built for students who know what a mean or a t-test is, but get stuck on the formulas themselves: what a subscript means, what a square root covers, whether to square before or after adding, which column of a table to read.

The app is anonymous and self-paced. It has no login, records nothing, and is not a quiz on R.

Developed by Glenn Tattersall (Department of Biological Sciences, Brock University) for BIOL 3P96, Statistical Analysis of Biological Data.

---

## What students do

- **Pick a topic** from the menus. Each topic shows a random set of 6 questions drawn from a larger bank.
- **Answer and check.** Feedback gives the correct answer, a short plain-language explanation that names the common mistake, the arithmetic worked step by step, and, for calculations, the **R code** that works out the same answer, using the same numbers. This links the notation to the code students write in the labs.
- **Practise again.** "New numbers" gives a calculation question a fresh dataset. "New set of questions" draws a different mix and favours questions not yet tried.
- **Reflect.** The Summary tab scores first attempts only, by topic and by skill, and links back to questions worth another look.

Every question practises one of three skills:

| Skill | What it practises |
|---|---|
| Symbols | What a mark or letter means (subscripts, hats, bars, Greek vs Roman letters, reused letters) |
| Reading structure | Order of operations: brackets, the scope of Σ, what a fraction bar or square root covers |
| Translating | Moving between formulas, plain English, and numbers, including reading statistical tables |

## Topics

| Menu | Topic | Examples |
|---|---|---|
| Foundations | 0. Basics | ≥ and ≤, comparing decimals, squaring negatives, negative exponents, ln and eˣ, R's `1.5e-04` notation, calculator brackets |
| | 1. Descriptive | Σ(Yᵢ)² vs (ΣYᵢ)², s and s², SE, median and quartile positions |
| | 2. Probability | "or", "and", "given", complements, Bayes' theorem |
| Categorical data | 3. Proportions | Binomial formula, n choose X, p vs p̂ vs p′ vs p₀ vs P |
| | 4. Goodness of fit | The χ² statistic, degrees of freedom, critical values, the Poisson formula |
| | 5. Categorical | Expected counts, (r − 1)(c − 1), odds, odds ratio, relative risk |
| Comparing means | 6. Normal distribution | Z for an observation vs a mean, Z tables, continuity correction |
| | 7. t-tests | t subscripted α(2) vs α(1), one-sample, paired and two-sample t, pooled variance |
| | 8. Non-parametric | Transformations (Y′), ranks and ties, Mann-Whitney U, sign test |
| | 9. ANOVA | N vs nᵢ vs k, SS, MS, F, R², Tukey-Kramer q |
| Relationships & design | 10. Correlation & regression | Sums of products, r, Fisher's z, Ŷ and residuals, slope and its SE |
| | 11. Models & design | Model statements (A*B), adjusted R², sample size, Cohen's d, power and β |

The bank currently holds 162 questions, with at least 12 per topic. About two-thirds of them generate new numbers on each visit.

## Running the app

The app uses **base R and the `shiny` package only**. It also runs on older R versions (before 4.1) and in the browser through Shinylive.

```r
install.packages("shiny")           # once
shiny::runApp("path/to/this/folder")
```

Keep `app.R` and `questions.csv` in the same folder.

**Math rendering:** formulas are drawn with MathJax 2.7.9 (CommonHTML output), loaded from cdnjs. An internet connection is needed. CommonHTML is used deliberately, because the default MathJax output misplaces hats (p̂, Ô) on Macs and iPads.

### Publishing with Shinylive (GitHub Pages)

```r
install.packages("shinylive")
shinylive::export(appdir = "path/to/this/folder", destdir = "docs")
```

Commit the `docs/` folder and point GitHub Pages at it. `questions.csv` is bundled into the export, so **re-export after editing the questions**.

## Files

```
app.R           the app (UI, question engine, scoring)
questions.csv   every question, one row per question
README.md       this file
```

## Adding or editing questions

All content lives in `questions.csv`, so questions can be added, edited or removed without touching `app.R`. Edit it in RStudio or a plain text editor rather than Excel, which can silently change cells that start with `=` or `-`.

| Column | Contents |
|---|---|
| `id` | Unique label (e.g. `TT4`) |
| `section` | Topic tab: `basics`, `descriptive`, `probability`, `proportions`, `fitting`, `categorical`, `normal`, `ttests`, `nonparam`, `anova`, `regression`, `models` |
| `skill` | `symbols`, `structure` or `translating` |
| `type` | `mc` (multiple choice), `tf` (true/false), `numeric`, or `order` (put steps in order) |
| `prompt` | Question text. Math goes inside `\( ... \)` in LaTeX |
| `choices` | Options (mc), steps in the correct order (order), or answer-box labels (numeric), separated by ` ;; ` |
| `answer` | mc: position of the correct option as listed. tf: `True` or `False` |
| `data` | Randomised questions only: R code that creates variables, e.g. `Y <- sample(1:9, 3)` |
| `answer_expr` | Numeric questions only: R code giving the answer(s), one value per answer box |
| `tolerance` | Allowed error: absolute (`0.01`) or relative (`1%`) |
| `explanation` | Plain-language feedback |
| `worked` | Optional worked arithmetic |
| `shuffle` | mc only: `no` keeps options in the listed order |
| `rcode` | Optional R code shown after checking, under "In R". `{{ }}` works here too, so the code uses the student's numbers |

Inside any text column, `{{ R code }}` is replaced by its value, e.g. `{{sum(Y^2)}}`. Leave a space between `{{ }}` and any LaTeX brace: `\dfrac{ {{s}} }{ {{n}} }`. Rows with an unknown `section` or `skill` are skipped without warning.

A minimal randomised question:

| prompt | data | answer_expr | tolerance | worked |
|---|---|---|---|---|
| `Your data are \(Y = \lbrace {{lst(Y)}} \rbrace\). Calculate \(\sum (Y_i)^2\).` | `Y <- sample(1:9, 3)` | `sum(Y^2)` | `0` | `\({{sqs(Y)}} = {{sum(Y^2)}}\)` |

The comment block at the top of `app.R` documents the helper functions (`lst()`, `plus()`, `sqs()`, `nice_sample()`).

### Checking an edited file

From the app folder, run this in the R console. It runs every question with 50 random datasets:

```r
source("app.R")
for (i in seq_len(nrow(Q))) for (cnt in 1:50) {
  env <- item_env(i, cnt)
  out <- vapply(c(Q$prompt[i], split_sep(Q$choices[i]), Q$explanation[i], Q$worked[i]),
                fill, "", env = env, USE.NAMES = FALSE)
  if (any(grepl("[error", out, fixed = TRUE))) { cat("Problem in", Q$id[i], "\n"); break }
}
table(Q$section, Q$skill)   # a skipped row shows up as a missing count
```

When you write an `rcode` entry, make it end with the answer, so that running the code reproduces it.

### Adding a topic

Topics are defined near the top of `app.R`. Add an entry to `sections` (tab label), `section_title`, `section_intro` (sidebar text) and `tips` (the topic's reading tips), then add the new key to one of the `tab_groups` menus.

## Design notes

- **Topic-based, not course-based.** The app never refers to specific tests, formula sheets or lecture numbers, so it stays valid if the course changes.
- **Table lookups** (t, F, χ², Z, Tukey q, Mann-Whitney U) compute their answers in R and match standard printed tables. Each draws only degrees of freedom and sample sizes that appear on typical tables.
- **Reading tips change with the topic.** Basics covers order of operations; later topics cover their own notation, such as α(2) vs α(1), N vs nᵢ vs k, and the two meanings of β.
- **iPad-friendly:** large tap targets, number keypads for numeric answers, and tap-to-order steps instead of drag-and-drop.
