# app.R
# Biostatistics Notational Practice: the notation and arithmetic of statistics
#
# Students practise reading statistical notation: symbols, the "grammar" of
# formulas (brackets, fraction bars, square roots), and translating between
# formulas, plain English, and numbers. Anonymous and self-paced: nothing is
# recorded, and answers vanish when the page is closed.
#
# Base R + shiny only. Math is rendered with MathJax 2 (CommonHTML output),
# loaded from the cdnjs web server, so an internet connection is needed.
# CommonHTML is used instead of shiny's withMathJax() because withMathJax()
# picks up the STIX fonts installed on Macs and iPads, which misplaces the
# hats on symbols such as p-hat.
#
# Each tab shows a random set of items_per_tab questions drawn from that
# section of questions.csv. Reloading the page, or tapping "New set of
# questions", gives a different set; New set prefers questions not yet tried.
#
# ---- Editing the questions --------------------------------------------------
# All items live in questions.csv (same folder as this file), one row per item.
# Edit it in RStudio or a plain text editor; Excel can silently change cells
# that start with "=" or "-". Columns:
#   id          unique short label (e.g. D1)
#   section     which tab the item appears on (one tab per topic):
#               basics | descriptive | probability | proportions | fitting |
#               categorical | normal | ttests | nonparam | anova |
#               regression | models
#               Items appear in the order they are listed in the file.
#   skill       what the item practises (shown on the card and in the Summary):
#               symbols | structure | translating
#   type        mc (multiple choice) | tf (true/false) | numeric | order
#   prompt      question text; LaTeX math goes inside \( ... \)
#   choices     mc: the options; order: the steps IN THE CORRECT ORDER;
#               numeric: a label for each answer box. Separate with ;;
#               (not |, which would clash with Pr[A|B]).
#   answer      mc: number of the correct option as listed; tf: True or False
#   data        numeric/randomized items only: R code that creates the
#               variables, e.g.  Y <- sample(1:9, 3)
#   answer_expr numeric items only: R code giving the answer(s), e.g.
#               c(sum(Y^2), sum(Y)^2)  -- one value per answer box
#   tolerance   numeric items only: how far off an answer can be (default 0.01);
#               write a percentage such as 1% to allow error relative to the answer
#   explanation plain-language feedback shown after checking
#   worked      optional worked arithmetic shown after checking
#   shuffle     mc only: write "no" to keep options in the listed order
#   rcode       optional R code that works out the answer, shown after checking
#               in a monospace box headed "In R". {{ }} works here too, so the
#               code uses the same numbers the student saw.
#
# Inside any text column, {{ R code }} is replaced by its value, e.g. {{sum(Y)}}.
# Leave a space between {{ }} and any LaTeX brace: \dfrac{ {{s}} }{ {{n}} }.
# For a curly bracket around data in LaTeX, use \lbrace and \rbrace.
# Helpers available in {{ }} and data: lst(Y) "2, 4, 6"; plus(Y) "2 + 4 + 6";
# sqs(Y) "2^2 + 4^2 + 6^2"; nice_sample(n, from, to) gives n different whole
# numbers whose mean is also a whole number.

library(shiny)

# ---- settings ---------------------------------------------------------------
items_per_tab <- 6   # questions drawn for each tab (all of them if fewer)

# ---- shared palette ---------------------------------------------------------
blue   <- "#569BBD"
teal   <- "#009499"
orange <- "#E07B39"
grey   <- "#C8C8C8"

# ---- sections: one tab per topic ---------------------------------------------
sections <- c(basics      = "1. Basics",
              descriptive = "2. Descriptive",
              probability = "3. Probability",
              proportions = "4. Proportions",
              fitting     = "5. Goodness of fit",
              categorical = "6. Categorical",
              normal      = "7. Normal distribution",
              ttests      = "8. t-tests",
              nonparam    = "9. Non-parametric",
              anova       = "10. ANOVA",
              regression  = "11. Correlation & regression",
              models      = "12. Models & design")

section_title <- c(basics      = "Basic operations and your calculator",
                   descriptive = "Descriptive statistics and estimating uncertainty",
                   probability = "Probability rules",
                   proportions = "Analysing proportions",
                   fitting     = "Goodness-of-fit tests",
                   categorical = "Associations between categorical variables",
                   normal      = "The normal distribution",
                   ttests      = "Comparing means with t-tests",
                   nonparam    = "Violated assumptions: transformations and ranks",
                   anova       = "Analysis of variance (ANOVA)",
                   regression  = "Correlation and regression",
                   models      = "Linear models and study design")

skills <- c(symbols     = "Symbols",
            structure   = "Reading structure",
            translating = "Translating")

skill_note <- c(
  symbols     = "What does this mark or letter mean?",
  structure   = "What gets done first, and what belongs to what?",
  translating = "Between formulas, words, and numbers"
)

section_intro <- list(
  basics = tagList(
    p(HTML(paste0(
      "Before the formulas: the arithmetic and calculator skills that every ",
      "formula depends on. These include reading \\(<\\), \\(>\\), \\(\\geq\\) ",
      "and \\(\\leq\\), comparing decimals, squaring negative numbers, ",
      "negative exponents, logarithms, percentages, R's scientific notation, ",
      "and rounding."))),
    p(strong("About your calculator:"), " a calculator does exactly what you ",
      "type, in strict order of operations. It cannot see a fraction bar or ",
      "the length of a square-root sign, so you often need to type brackets ",
      "that are only implied on paper.")
  ),
  descriptive = tagList(
    p(HTML(paste0(
      "The mean \\(\\bar{Y}\\), variance \\(s^2\\), standard deviation ",
      "\\(s\\), coefficient of variation \\(CV\\), standard error ",
      "\\(SE_{\\bar{Y}}\\), the median and quartiles, and an approximate 95% ",
      "confidence interval."))),
    p("These formulas reuse the same few pieces many times, so reading one well ",
      "helps you read them all.")
  ),
  probability = tagList(
    p(HTML(paste0(
      "Probability rules for combining events: \\(Pr[A\\ \\text{or}\\ B]\\), ",
      "\\(Pr[A\\ \\text{and}\\ B]\\), conditional probability \\(Pr[A|B]\\), ",
      "the complement \\(B^c\\), and Bayes' theorem."))),
    p("Here the words ", em("or"), ", ", em("and"), ", and ", em("given"),
      " each have one exact meaning. Read them carefully.")
  ),
  proportions = tagList(
    p(HTML(paste0(
      "The binomial formula, \\(\\binom{n}{X}\\), the binomial P-value, and ",
      "the standard error and confidence interval for a proportion."))),
    p(HTML(paste0(
      "Watch the different kinds of p: \\(P\\), \\(p\\), \\(\\hat{p}\\), ",
      "\\(p'\\) and \\(p_0\\) are five different things.")))
  ),
  fitting = tagList(
    p(HTML(paste0(
      "Does a probability model fit the data? The \\(\\chi^2\\) goodness-of-fit ",
      "statistic, its degrees of freedom and critical values, and the Poisson ",
      "formula for the probability of \\(X\\) events."))),
    p("The \\(\\chi^2\\) formula looks long, but it is one small calculation ",
      "repeated for each category and then added up.")
  ),
  categorical = tagList(
    p(HTML(paste0(
      "Contingency tables: expected counts \\(Expected_{ij}\\), degrees of ",
      "freedom \\((r-1)(c-1)\\), odds \\(\\hat{O}\\), the odds ratio \\(OR\\) ",
      "and relative risk \\(RR\\)."))),
    p("Subscripts here work like addresses, pointing to a row, a column, or ",
      "a group.")
  ),
  normal = tagList(
    p(HTML(paste0(
      "Standardising with \\(Z\\), the difference between \\(\\sigma\\) and ",
      "\\(\\sigma_{\\bar{Y}}\\), reading upper-tail probabilities, and using ",
      "the normal distribution to approximate a binomial count."))),
    p("Tables of the standard normal distribution list only positive values ",
      "of z. Symmetry and the complement rule do the rest.")
  ),
  ttests = tagList(
    p(HTML(paste0(
      "One-sample, paired and two-sample t-tests: critical values ",
      "\\(t_{\\alpha(2),df}\\), standard errors, pooled variance \\(s_p^2\\), ",
      "and degrees of freedom."))),
    p(HTML(paste0(
      "Subscripts carry a lot of information here: \\(\\alpha(2)\\) versus ",
      "\\(\\alpha(1)\\), \\(\\mu_0\\), and \\(SE_{\\bar{Y}_1 - \\bar{Y}_2}\\).")))
  ),
  nonparam = tagList(
    p(HTML(paste0(
      "What to do when assumptions fail: transformed data \\(Y'\\), natural ",
      "logs and back-transformation, and tests based on ranks: the ",
      "Mann-Whitney U test and the sign test."))),
    p("Ranking has its own rules, especially for tied values.")
  ),
  anova = tagList(
    p(HTML(paste0(
      "Comparing more than two means: sums of squares, mean squares, the ",
      "\\(F\\) ratio, \\(R^2\\), and Tukey-Kramer comparisons."))),
    p(HTML(paste0(
      "Keep three letters apart: \\(N\\) (all observations), \\(n_i\\) (one ",
      "group) and \\(k\\) (the number of groups).")))
  ),
  regression = tagList(
    p(HTML(paste0(
      "Correlation \\(r\\) and regression \\(Y = a + bX\\): sums of squares ",
      "and products, standard errors, Fisher's \\(z\\), predicted values ",
      "\\(\\hat{Y}\\) and residuals."))),
    p(HTML(paste0(
      "Roman letters (\\(r\\), \\(b\\)) are sample estimates; Greek letters ",
      "(\\(\\rho\\), \\(\\beta\\)) are population values.")))
  ),
  models = tagList(
    p("Model statements such as RESPONSE = CONSTANT + A + B + A*B, adjusted ",
      HTML("\\(R^2\\)"), ", sample-size planning, effect size and power."),
    p("Model statements describe hypotheses. The plus signs mean 'include ",
      "this term', not 'add these numbers'.")
  )
)

# Reading tips, written for each topic. Each entry is one bullet point;
# math goes inside \\( ... \\) as elsewhere.
tips <- list(
  basics = c(
    "Work from the inside out: innermost brackets first, then powers and square roots, then multiplying and dividing, then adding and subtracting.",
    "Symbols written side by side are multiplied: \\(2SE\\) means \\(2 \\times SE\\), and \\(\\cdot\\) also means multiply.",
    "A square-root sign and a fraction bar act like roofs: they cover only what sits under or over them.",
    "A small raised number is a power; a small lowered letter or number (a subscript) is a name tag.",
    "On a calculator, type the brackets that paper only implies, and test how your \\(\\sqrt{\\ }\\) and \\(x^2\\) keys behave."
  ),
  descriptive = c(
    "\\(\\sum\\) means 'add up'. With no numbers above or below it, add up every observation.",
    "The subscript \\(i\\) in \\(Y_i\\) means 'each observation in turn', so \\(\\sum (Y_i - \\bar{Y})\\) does the bracket once for every value.",
    "Watch where the square sits: \\(\\sum (Y_i)^2\\) squares each value before adding; \\((\\sum Y_i)^2\\) squares the total.",
    "A bar means 'mean of': \\(\\bar{Y}\\) is the mean of the \\(Y\\) values.",
    "Median and quartile formulas give a <i>position</i> in the sorted data, not a value."
  ),
  probability = c(
    "'Or' includes both: \\(Pr[A\\ \\text{or}\\ B]\\) counts outcomes where \\(A\\), \\(B\\), or both happen.",
    "'And' means both happen, and it usually means multiply.",
    "The bar in \\(Pr[A|B]\\) reads 'given': the probability of \\(A\\) among outcomes where \\(B\\) has happened. Order matters.",
    "A raised \\(c\\), as in \\(B^c\\), means 'not': \\(Pr[B^c] = 1 - Pr[B]\\).",
    "Sanity check: every probability lies between 0 and 1. 'And' answers are smaller than either part; 'or' answers are larger."
  ),
  proportions = c(
    "A hat marks an estimate: \\(\\hat{p}\\) is the proportion in your sample, estimating the true \\(p\\).",
    "Keep the p's apart: \\(p\\), \\(\\hat{p}\\), \\(p'\\), \\(p_0\\) and capital \\(P\\) are five different things.",
    "\\(n!\\) is a factorial; the tall brackets \\(\\binom{n}{X}\\) mean 'n choose X', not a fraction.",
    "The numbers below and above \\(\\sum\\) say where counting starts and stops.",
    "\\(1 - p\\) is the probability of failure; work it out before raising it to a power."
  ),
  fitting = c(
    "The \\(\\sum\\) runs over categories: one fraction per category, then add.",
    "The subscript \\(i\\) ties \\(Observed_i\\) and \\(Expected_i\\) to the same category.",
    "In each term, subtract, then square, then divide by that category's expected count.",
    "Expected counts come from the null hypothesis, not from the data.",
    "\\(df\\) = categories \\(-\\) parameters estimated \\(-\\) 1. \\(\\chi^2\\) tests use only the upper tail."
  ),
  categorical = c(
    "Double subscripts are addresses: \\(Expected_{ij}\\) is row \\(i\\), column \\(j\\).",
    "\\(R_i\\) and \\(C_j\\) are row and column totals; \\(n\\) is the grand total.",
    "A proportion divides by everyone; odds divide by those without the outcome.",
    "A single subscript names a group: \\(\\hat{O}_1\\) is group 1's odds.",
    "A ratio of 1 (\\(OR\\) or \\(RR\\)) means no difference between the groups."
  ),
  normal = c(
    "Greek letters (\\(\\mu\\), \\(\\sigma\\)) are population values; Roman letters (\\(\\bar{Y}\\), \\(s\\)) come from samples.",
    "\\(\\sigma\\) is the spread of single values; \\(\\sigma_{\\bar{Y}} = \\frac{\\sigma}{\\sqrt{n}}\\) is the spread of sample means.",
    "In \\(Z = \\frac{Y - \\mu}{\\sigma}\\), finish the top line before dividing, and keep the sign.",
    "An upper-tail table gives \\(Pr[Z > z]\\). Use symmetry for negative \\(z\\), and \\(1 -\\) the table value for 'less than'.",
    "\\(\\geq\\) and \\(\\leq\\) include the observed count, which is why the \\(\\frac{1}{2}\\) correction is needed."
  ),
  ttests = c(
    "\\(\\alpha(2)\\) is two-tailed and \\(\\alpha(1)\\) is one-tailed; \\(\\alpha(2) = 0.05\\) uses the same column as \\(\\alpha(1) = 0.025\\).",
    "In \\(t_{\\alpha(2),df}\\), the first part picks the column of the table and \\(df\\) picks the row.",
    "A subscript 0 (\\(\\mu_0\\), \\((\\mu_1 - \\mu_2)_0\\)) marks the value stated by the null hypothesis.",
    "Check whether you are given \\(s\\) or \\(s^2\\); pooled variance needs variances.",
    "Paired designs: subtract within each pair first, then treat the differences \\(d\\) as one sample."
  ),
  nonparam = c(
    "A prime marks a modified value: \\(Y'\\) is transformed \\(Y\\). (\\(p'\\) has other meanings elsewhere.)",
    "\\(\\ln\\) is the natural log (the <b>ln</b> key, and <code>log()</code> in R); \\(e^x\\) undoes it.",
    "A transformation applies to every value, not only the awkward ones.",
    "Rank both groups together; tied values share the average of their ranks.",
    "\\(\\max(U_1, U_2)\\) means the larger of the two."
  ),
  anova = c(
    "Capital \\(N\\) is all observations; \\(n_i\\) is group \\(i\\); \\(k\\) is the number of groups.",
    "Each \\(MS\\) is its own \\(SS\\) divided by its own \\(df\\).",
    "Sums of squares add up (\\(SS_{total} = SS_{groups} + SS_{error}\\)); mean squares do not.",
    "In \\(F_{\\alpha(1), df_1, df_2}\\), \\(df_1\\) (groups) comes first and \\(df_2\\) (error) second.",
    "A grand mean from group means is weighted by group size: \\(\\frac{\\sum (n_i \\bar{Y}_i)}{N}\\)."
  ),
  regression = c(
    "Roman letters are estimates (\\(r\\), \\(b\\)); Greek letters are population values (\\(\\rho\\), \\(\\beta\\)).",
    "A hat means predicted: \\(\\hat{Y}\\) is on the line, and \\(e_i = Y_i - \\hat{Y}_i\\) is the residual.",
    "\\(S_{XY}\\) multiplies within each pair, then adds; \\(SS_X\\) squares, then adds.",
    "Square roots and fraction bars cover a lot here: finish what is under the roof first.",
    "The letter \\(R\\) means different things in different questions, so always read it in the context of the question: in Spearman's correlation, \\(R\\) is the ranks of X; in a Mann-Whitney test, \\(R_1\\) is a rank sum; in a contingency table, \\(R_i\\) is a row total; and \\(R^2\\) is the proportion of variation explained. Lower-case \\(r\\) is the correlation coefficient."
  ),
  models = c(
    "Model statements are not arithmetic: '+' means 'include this term'.",
    "A*B is the interaction: the effect of A depends on the level of B.",
    "CONSTANT is the overall mean or intercept.",
    "In \\(R^2_{adj}\\), \\(p\\) counts predictors; it is not a proportion.",
    "\\(\\beta\\) has two jobs: a population slope, and the Type II error rate in \\(Power = 1 - \\beta\\).",
    "Always round planned sample sizes up."
  )
)

tips_ui <- function(sec) {
  items <- tips[[sec]]
  tagList(
    p(strong("Reading tips for this topic")),
    tags$ul(style = "padding-left:18px;",
            lapply(items, function(x) tags$li(HTML(x))))
  )
}

SEP <- ";;"

# ---- reading the question file ----------------------------------------------
read_questions <- function(path = "questions.csv") {
  q <- read.csv(path, colClasses = "character", na.strings = character(0),
                fileEncoding = "UTF-8-BOM", check.names = FALSE)
  needed <- c("id", "section", "skill", "type", "prompt", "choices", "answer", "data",
              "answer_expr", "tolerance", "explanation", "worked", "shuffle", "rcode")
  for (nm in setdiff(needed, names(q))) q[[nm]] <- ""
  for (nm in needed) q[[nm]] <- trimws(q[[nm]])
  q$section <- tolower(q$section)
  q$skill   <- tolower(q$skill)
  q$type    <- tolower(q$type)
  q <- q[q$section %in% names(sections) &
         q$type %in% c("mc", "tf", "numeric", "order"), , drop = FALSE]
  if (any(duplicated(q$id)))
    stop("questions.csv: these ids are used more than once: ",
         paste(unique(q$id[duplicated(q$id)]), collapse = ", "))
  rownames(q) <- NULL
  q
}

Q <- read_questions()
sec_rows <- lapply(names(sections), function(s) which(Q$section == s))
names(sec_rows) <- names(sections)

split_sep <- function(x) {
  if (is.null(x) || !nzchar(trimws(x))) return(character(0))
  trimws(strsplit(x, SEP, fixed = TRUE)[[1]])
}

# ---- number formatting and {{ }} substitution -------------------------------
fmt_num <- function(v) {
  if (!is.numeric(v)) return(as.character(v))
  vapply(v, function(z) {
    if (is.na(z)) return("?")
    format(round(z, 4), scientific = FALSE, trim = TRUE, drop0trailing = TRUE)
  }, "", USE.NAMES = FALSE)
}

helpers <- new.env(parent = globalenv())
helpers$lst  <- function(x) paste(fmt_num(x), collapse = ", ")
helpers$plus <- function(x) paste(fmt_num(x), collapse = " + ")
helpers$sqs  <- function(x) {
  s <- fmt_num(x)
  s <- ifelse(x < 0, paste0("(", s, ")"), s)
  paste0(s, "^2", collapse = " + ")
}
helpers$nice_sample <- function(n, from, to) {
  for (tries in 1:500) {
    y <- sample(from:to, n)
    if (sum(y) %% n == 0) return(y)
  }
  y
}

fill <- function(txt, env) {
  if (is.null(txt) || !nzchar(txt)) return("")
  m <- gregexpr("\\{\\{(.+?)\\}\\}", txt, perl = TRUE)
  parts <- regmatches(txt, m)[[1]]
  if (length(parts) == 0) return(txt)
  vals <- vapply(parts, USE.NAMES = FALSE, FUN.VALUE = "", FUN = function(pp) {
    code <- substr(pp, 3, nchar(pp) - 2)
    out <- tryCatch(eval(parse(text = code), envir = env),
                    error = function(e) paste0("[error: ", conditionMessage(e), "]"))
    if (!is.atomic(out)) out <- paste0("[error: '", code, "' is not a value]")
    paste(fmt_num(out), collapse = ", ")
  })
  regmatches(txt, m) <- list(vals)
  txt
}

# Build the variables for one item. The same seed always gives the same numbers.
item_env <- function(i, count) {
  env <- new.env(parent = helpers)
  code <- Q$data[i]
  if (nzchar(code)) {
    # Fixed seed so the same item + dataset number always gives the same
    # numbers, then put the random number stream back as it was, so that
    # question draws and shuffles stay random between visits.
    old_seed <- get0(".Random.seed", envir = globalenv(), inherits = FALSE)
    on.exit(if (is.null(old_seed)) {
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
        rm(".Random.seed", envir = globalenv())
    } else assign(".Random.seed", old_seed, envir = globalenv()))
    set.seed(1000 * count + i)
    tryCatch(eval(parse(text = code), envir = env),
             error = function(e) assign(".data_error", conditionMessage(e), envir = env))
  }
  env
}

item_target <- function(i, env) {
  out <- tryCatch(eval(parse(text = Q$answer_expr[i]), envir = env),
                  error = function(e) NA_real_)
  as.numeric(out)
}

# Allowed error for each answer box. A plain number is an absolute allowance;
# a percentage (e.g. "1%") is relative to the correct answer.
item_tol <- function(i, target) {
  txt <- gsub(" ", "", Q$tolerance[i])
  if (grepl("%$", txt)) {
    pct <- suppressWarnings(as.numeric(sub("%$", "", txt)))
    if (!is.na(pct)) return(abs(target) * pct / 100)
  }
  t <- suppressWarnings(as.numeric(txt))
  if (length(t) == 0 || is.na(t)) 0.01 else t
}

safe_id <- function(x) gsub("[^A-Za-z0-9]", "_", x)

# Ask MathJax to typeset any math in newly drawn content
mj <- function(...) {
  tagList(..., tags$script(HTML(
    "if (window.MathJax) MathJax.Hub.Queue(['Typeset', MathJax.Hub]);")))
}

# JavaScript for tappable elements (dots, steps, small buttons).
# Uses Shiny's own setInputValue, so no extra libraries are needed.
js_evt <- function(action, sec, k = 0) {
  sprintf("Shiny.setInputValue('evt', {a:'%s', s:'%s', k:%d}, {priority:'event'});",
          action, sec, as.integer(k))
}

# ================================ UI =========================================
section_tab <- function(sec) {
  tabPanel(
    sections[[sec]], value = sec,
    br(),
    fluidRow(
      column(
        width = 4,
        wellPanel(
          p(strong(section_title[[sec]])),
          div(style = "font-size:16px; line-height:1.6;", section_intro[[sec]])
        ),
        wellPanel(div(style = "font-size:15px; line-height:1.6;", tips_ui(sec)))
      ),
      column(
        width = 8,
        uiOutput(paste0("prog_", sec)),
        wellPanel(class = "qcard", uiOutput(paste0("q_", sec))),
        div(class = "navrow",
            actionButton(paste0("check_", sec), "Check my answer"),
            div(style = "float:right;",
                actionButton(paste0("prev_", sec), "Previous"),
                actionButton(paste0("next_", sec), "Next"))),
        uiOutput(paste0("fb_", sec))
      )
    )
  )
}

ui <- fluidPage(
  tags$head(
    tags$script(type = "text/x-mathjax-config", HTML(
      "MathJax.Hub.Config({ messageStyle: 'none',",
      "  CommonHTML: { linebreaks: { automatic: true } } });")),
    tags$script(src = paste0("https://cdnjs.cloudflare.com/ajax/libs/mathjax/",
                             "2.7.9/MathJax.js?config=TeX-AMS_CHTML"))
  ),
  titlePanel("Biostatistics Notational Practice",
             windowTitle = "Biostatistics Notational Practice"),

  tags$head(tags$style(HTML(paste0(
    ".action-button, .qbtn { color:#fff; background-color:", blue, "; border:none;",
    "  font-size:16px; padding:10px 18px; margin:4px 4px 4px 0; border-radius:4px; }",
    ".action-button:hover, .qbtn:hover { color:#fff; background-color:#3E7C99; }",
    ".action-button:active, .qbtn:active { transform:scale(0.97); }",
    ".qbtn-light { color:", blue, "; background-color:#fff; border:2px solid ", blue, "; }",
    ".qbtn-light:hover { color:#fff; }",
    ".skilltag { font-size:14px; color:#666; margin-bottom:8px; }",
    ".prompt { font-size:18px; line-height:1.6; margin-bottom:14px; }",
    ".qcard .radio label { font-size:17px; line-height:1.5; padding:8px 0 8px 26px; }",
    ".qcard .radio input[type=radio] { transform:scale(1.4); margin-top:8px; }",
    ".qcard .shiny-input-container { margin-bottom:6px; }",
    ".qcard input[type=number] { font-size:18px; height:44px; }",
    ".qcard .control-label { font-size:17px; font-weight:normal; }",
    ".numbox { display:inline-block; vertical-align:top; margin-right:24px; width:200px; }",
    ".step-btn { display:block; width:100%; text-align:left; white-space:normal;",
    "  font-size:17px; padding:10px 14px; margin:6px 0; background:#fff;",
    "  border:2px solid ", blue, "; border-radius:6px; color:#222; }",
    ".step-btn:active { transform:scale(0.99); }",
    ".dot { display:inline-block; width:38px; height:38px; line-height:38px;",
    "  border-radius:50%; text-align:center; color:#fff; font-weight:700;",
    "  margin:3px 5px 3px 0; cursor:pointer; user-select:none; }",
    ".dot-current { box-shadow:0 0 0 3px #fff, 0 0 0 6px #3E7C99; }",
    ".prog-text { font-size:15px; color:#555; margin:4px 0 10px 0; }",
    ".navrow { overflow:hidden; margin-bottom:12px; }",
    ".fb { font-size:17px; line-height:1.6; padding:14px 18px; border-radius:6px;",
    "  background:#f7f7f7; margin-bottom:20px; }",
    ".fb-correct { border-left:8px solid ", teal, "; }",
    ".fb-wrong   { border-left:8px solid ", orange, "; }",
    ".fb-note    { border-left:8px solid ", grey, "; }",
    ".fb h4 { margin-top:0; font-weight:700; }",
    ".rcode { background:#fff; font-size:14px; line-height:1.5; padding:10px 14px;",
    "  border-left:4px solid ", teal, "; border-radius:4px; margin-top:8px;",
    "  white-space:pre-wrap; word-break:break-word; color:#222; }",
    ".worked { background:#fff; padding:10px 14px; border-radius:4px;",
    "  margin-top:8px; line-height:2; overflow-x:auto; }",
    ".sumtab { font-size:17px; border-collapse:collapse; margin:10px 0 20px 0; }",
    ".sumtab td, .sumtab th { padding:8px 16px; border-bottom:1px solid #ddd; }",
    ".revisit { color:", blue, "; cursor:pointer; text-decoration:underline; }"
  )))),

  tabsetPanel(
    id = "tabs", type = "tabs",

    # ======= START ==========================================================
    tabPanel(
      "Start", value = "start",
      br(),
      fluidRow(
        column(
          width = 8,
          h2("Reading statistical notation",
             style = paste0("color:", teal, "; font-weight:700;")),
          p(style = "font-size:17px; line-height:1.6;",
            "Statistical formulas are written in a compact language. Each symbol ",
            "is a word, and the layout of the formula (what sits inside brackets, ",
            "under a square root, or above a fraction bar) is its grammar. You can ",
            "know every word and still misread the sentence if the grammar is ",
            "unfamiliar."),
          p(style = "font-size:17px; line-height:1.6;",
            "This self-check helps you practise reading that language, using ",
            "the formulas and symbols that come up in Biostatistics. It is not ",
            "about R, and it is not graded."),
          br(),
          h4(style = paste0("color:", teal, ";"), "How it works"),
          tags$ol(
            style = "font-size:16px; line-height:1.9;",
            tags$li(strong("Pick a topic"), " from the tabs above. ",
                    strong("1. Basics"), " covers arithmetic and ",
                    "calculator skills; if maths is not your strong point, start ",
                    "there. The other topics can be done in any order."),
            tags$li(strong("Notice the skill."), " Each item says whether it ",
                    "practises ", em("symbols"), " (what a mark means), ",
                    em("reading structure"), " (what gets done first), or ",
                    em("translating"), " (between formulas, words and numbers)."),
            tags$li(strong("Answer, then tap Check my answer."), " You will see the ",
                    "correct answer, a short explanation, and, for calculations, ",
                    "the arithmetic worked out step by step."),
            tags$li(strong("Try again with New numbers."), " Calculation items can ",
                    "give you a fresh dataset, so you can practise until it ",
                    "feels easy."),
            tags$li(strong("Get a different mix."), " Each section shows a set of ",
                    items_per_tab, " questions drawn from a larger bank. Tap ",
                    em("New set of questions"), " (or reload the page) for a ",
                    "different mix. New sets favour questions you have not ",
                    "tried yet."),
            tags$li(strong("Check the Summary tab"), " to see which items to revisit.")
          ),
          br(),
          p(style = "font-size:15px; color:#555;",
            em("Have a calculator and your statistical tables beside you, and do ",
               "the arithmetic on paper."))
        ),
        column(
          width = 4,
          br(),
          wellPanel(
            p(strong("Nothing is recorded")),
            p("There is no login, and nothing you enter is saved or sent anywhere. ",
              "Your answers disappear when you close or reload this page."),
            p("The summary counts your ", em("first"), " try at each question, so ",
              "you get an honest picture of where you started. Retrying is ",
              "encouraged and does not change it. Reloading the page starts ",
              "everything fresh, including the summary."),
            hr(),
            helpText("Glenn Tattersall, PhD"),
            helpText("For use in BIOL 3P96 - Biostatistics")
          )
        )
      )
    ),

    # One tab per topic, in the order of `sections`; they wrap onto a second row
    # on narrower screens such as an iPad.
    section_tab("basics"),
    section_tab("descriptive"),
    section_tab("probability"),
    section_tab("proportions"),
    section_tab("fitting"),
    section_tab("categorical"),
    section_tab("normal"),
    section_tab("ttests"),
    section_tab("nonparam"),
    section_tab("anova"),
    section_tab("regression"),
    section_tab("models"),

    # ======= SUMMARY ========================================================
    tabPanel(
      "Summary", value = "summary",
      br(),
      fluidRow(
        column(
          width = 8,
          h2("Your summary",
             style = paste0("color:", teal, "; font-weight:700;")),
          uiOutput("summary"),
          br(),
          actionButton("reset_all", "Clear all my answers")
        ),
        column(
          width = 4,
          br(),
          wellPanel(
            p(strong("Using this for reflection")),
            p(HTML(paste0(
              "The <b>By skill</b> table is often the more useful one. If most of ",
              "your items to revisit are <b>Reading structure</b>, practise reading ",
              "formulas from the inside out, out loud, before calculating anything."))),
            p(HTML(paste0(
              "If they are mostly <b>Symbols</b>, try writing your own one-line ",
              "glossary: each symbol you meet, and what it means in words."))),
            p(HTML(paste0(
              "If they are mostly <b>Translating</b>, say each formula as a full ",
              "sentence before you use it."))),
            p("Then try your course's practice questions, which use the same ",
              "notation.")
          )
        )
      )
    )
  )
)

# ================================ SERVER =====================================
server <- function(input, output, session) {

  # Shuffled display orders, fixed for the whole session
  perms <- lapply(seq_len(nrow(Q)), function(i) {
    n <- length(split_sep(Q$choices[i]))
    if (n < 2) return(seq_len(n))
    if (Q$type[i] == "mc" && tolower(Q$shuffle[i]) != "no") return(sample(n))
    if (Q$type[i] == "order") {
      p <- sample(n)
      while (identical(p, seq_len(n))) p <- sample(n)
      return(p)
    }
    seq_len(n)
  })

  blank_pos <- function() {
    x <- as.list(rep(1L, length(sections))); names(x) <- names(sections); x
  }

  # Draw a set of questions for one section, preferring ones not yet tried.
  # Items are shown in the order they appear in questions.csv.
  draw_set <- function(sec, tried_ids = character(0)) {
    rows <- sec_rows[[sec]]
    if (length(rows) <= items_per_tab) return(rows)
    fresh <- rows[!(Q$id[rows] %in% tried_ids)]
    done  <- rows[Q$id[rows] %in% tried_ids]
    pick_from <- function(x, m) if (length(x) <= m) x else x[sample.int(length(x), m)]
    picked <- pick_from(fresh, items_per_tab)
    if (length(picked) < items_per_tab)
      picked <- c(picked, pick_from(done, items_per_tab - length(picked)))
    sort(picked)
  }
  all_sets <- function(tried_ids = character(0)) {
    x <- lapply(names(sections), draw_set, tried_ids = tried_ids)
    names(x) <- names(sections); x
  }

  # Different numbers for the calculation items on each visit
  data_offset <- sample.int(5000, 1)

  rv <- reactiveValues(
    set     = all_sets(),   # rows of questions.csv drawn for each section
    pos     = blank_pos(),  # current item number within each section
    count   = list(),       # dataset number for each item (New numbers)
    first   = list(),       # result of the first try at each item
    fb      = list(),       # feedback for each item + dataset
    resp    = list(),       # last answer given, so it reappears on return
    picks   = list()        # taps so far, for ordering items
  )

  cur_index <- function(sec) {
    rows <- rv$set[[sec]]
    if (length(rows) == 0) return(NA_integer_)
    k <- min(max(1L, rv$pos[[sec]]), length(rows))
    rows[k]
  }
  count_of <- function(id) {
    x <- rv$count[[id]]
    if (is.null(x)) 1L else x
  }
  key_of   <- function(i, cnt) paste0(Q$id[i], "#", cnt)
  rid_of   <- function(i, cnt) paste0("r_", safe_id(Q$id[i]), "_", cnt)
  steps_of <- function(i, env) vapply(split_sep(Q$choices[i]), fill, "", env = env, USE.NAMES = FALSE)

  # Text of the correct answer, for the feedback panel
  answer_html <- function(i, env) {
    type <- Q$type[i]
    if (type == "mc") {
      ch <- split_sep(Q$choices[i])
      k <- suppressWarnings(as.integer(Q$answer[i]))
      if (is.na(k) || k < 1 || k > length(ch)) return("(answer missing in questions.csv)")
      return(fill(ch[k], env))
    }
    if (type == "tf") return(if (substr(tolower(Q$answer[i]), 1, 1) == "t") "True" else "False")
    if (type == "numeric") {
      target <- item_target(i, env)
      labs <- vapply(split_sep(Q$choices[i]), fill, "", env = env, USE.NAMES = FALSE)
      if (length(labs) < length(target)) labs <- c(labs, rep("", length(target) - length(labs)))
      return(paste(paste(labs[seq_along(target)], fmt_num(target)), collapse = "; "))
    }
    if (type == "order") {
      st <- steps_of(i, env)
      return(paste0("<ol style='margin:6px 0 0 0;'>",
                    paste0("<li>", st, "</li>", collapse = ""), "</ol>"))
    }
    ""
  }

  # ---------------- per-section outputs and buttons -------------------------
  lapply(names(sections), function(sec) {

    # Progress dots: grey = not tried, teal = right first time, orange = revisit
    output[[paste0("prog_", sec)]] <- renderUI({
      rows <- rv$set[[sec]]
      if (length(rows) == 0) return(NULL)
      now <- rv$pos[[sec]]
      tried <- 0
      dots <- lapply(seq_along(rows), function(k) {
        res <- rv$first[[Q$id[rows[k]]]]
        col <- if (is.null(res)) grey else if (res) teal else orange
        if (!is.null(res)) tried <<- tried + 1
        tags$span(class = paste("dot", if (k == now) "dot-current"),
                  style = paste0("background:", col, ";"),
                  onclick = js_evt("jump", sec, k), k)
      })
      tagList(
        div(dots),
        div(class = "prog-text",
            paste0("Question ", now, " of ", length(rows), " in this set. ",
                   "You have tried ", tried, " of these ", length(rows), ". ",
                   "Tap a number to jump to that question.")),
        if (length(sec_rows[[sec]]) > length(rows))
          div(class = "prog-text",
              paste0("This section has ", length(sec_rows[[sec]]),
                     " questions in all. "),
              tags$button(type = "button", class = "qbtn qbtn-light",
                          style = "font-size:15px; padding:6px 12px; margin-left:6px;",
                          onclick = js_evt("newset", sec), "New set of questions"))
      )
    })

    # The question itself (does not redraw when you check an answer)
    output[[paste0("q_", sec)]] <- renderUI({
      i <- cur_index(sec)
      if (is.na(i)) return(p("There are no questions in this section yet."))
      cnt  <- count_of(Q$id[i])
      env  <- item_env(i, cnt + data_offset)
      rid  <- rid_of(i, cnt)
      key  <- key_of(i, cnt)
      prev <- isolate(rv$resp[[key]])
      type <- Q$type[i]

      widget <- NULL
      if (type == "mc") {
        ch <- vapply(split_sep(Q$choices[i]), fill, "", env = env, USE.NAMES = FALSE)
        pm <- perms[[i]]
        widget <- radioButtons(rid, NULL, width = "100%",
                               choiceNames  = lapply(ch[pm], HTML),
                               choiceValues = as.character(pm),
                               selected = if (is.null(prev)) character(0) else prev)
      } else if (type == "tf") {
        widget <- radioButtons(rid, NULL, choices = c("True", "False"),
                               selected = if (is.null(prev)) character(0) else prev)
      } else if (type == "numeric") {
        target <- item_target(i, env)
        labs <- vapply(split_sep(Q$choices[i]), fill, "", env = env, USE.NAMES = FALSE)
        nbox <- max(1, length(target))
        if (length(labs) < nbox) labs <- c(labs, rep("Your answer", nbox - length(labs)))
        widget <- lapply(seq_len(nbox), function(k) {
          v <- if (is.null(prev)) NA else prev[k]
          div(class = "numbox",
              numericInput(paste0(rid, "_", k), HTML(labs[k]), value = v, width = "100%"))
        })
      } else if (type == "order") {
        st <- steps_of(i, env)
        widget <- tagList(
          lapply(perms[[i]], function(j) {
            tags$button(type = "button", class = "step-btn",
                        id = paste0("step_", sec, "_", j),
                        onclick = js_evt("pick", sec, j), HTML(st[j]))
          }),
          uiOutput(paste0("ord_", sec)),
          tags$button(type = "button", class = "qbtn qbtn-light",
                      onclick = js_evt("undo", sec), "Undo"),
          tags$button(type = "button", class = "qbtn qbtn-light",
                      onclick = js_evt("clear", sec), "Clear")
        )
      }

      newbtn <- NULL
      if (nzchar(Q$data[i])) {
        newbtn <- div(style = "margin-top:10px;",
                      tags$button(type = "button", class = "qbtn",
                                  onclick = js_evt("new", sec), "New numbers"),
                      span(style = "color:#777; font-size:14px; margin-left:8px;",
                           paste0("Dataset ", cnt)))
      }

      mj(tagList(
        if (Q$skill[i] %in% names(skills))
          div(class = "skilltag",
              strong(skills[[Q$skill[i]]]), " - ", skill_note[[Q$skill[i]]]),
        div(class = "prompt", HTML(fill(Q$prompt[i], env))),
        widget,
        newbtn
      ))
    })

    # The order tapped so far, for ordering items
    output[[paste0("ord_", sec)]] <- renderUI({
      i <- cur_index(sec)
      if (is.na(i) || Q$type[i] != "order") return(NULL)
      cnt <- count_of(Q$id[i])
      st  <- steps_of(i, item_env(i, cnt + data_offset))
      pk  <- rv$picks[[key_of(i, cnt)]]
      used_css <- if (length(pk) > 0)
        tags$style(HTML(paste0(paste0("#step_", sec, "_", pk, collapse = ", "),
                               " { opacity:0.35; }")))
      body <- if (length(pk) == 0) {
        p(style = "color:#777; margin:10px 0;", em("Your order will build up here as you tap."))
      } else {
        div(style = "margin:12px 0;",
            p(strong(paste0("Your order so far (", length(pk), " of ", length(st), "):")),
              style = "margin-bottom:4px;"),
            tags$ol(style = "font-size:17px; line-height:1.7;",
                    lapply(pk, function(j) tags$li(HTML(st[j])))))
      }
      mj(tagList(used_css, body))
    })

    # Feedback panel
    output[[paste0("fb_", sec)]] <- renderUI({
      i <- cur_index(sec)
      if (is.na(i)) return(NULL)
      cnt <- count_of(Q$id[i])
      fb  <- rv$fb[[key_of(i, cnt)]]
      if (is.null(fb)) return(NULL)
      if (fb$status == "incomplete")
        return(div(class = "fb fb-note", fb$msg))
      env <- item_env(i, cnt + data_offset)
      ok  <- fb$status == "correct"
      worked <- fill(Q$worked[i], env)
      rcode  <- fill(Q$rcode[i], env)
      mj(div(
        class = paste("fb", if (ok) "fb-correct" else "fb-wrong"),
        h4(style = paste0("color:", if (ok) teal else orange, ";"),
           if (ok) "Correct." else "Not quite."),
        if (!is.null(fb$yours)) p(HTML(paste0("You entered: ", fb$yours))),
        p(HTML(paste0("<b>The answer:</b> ", answer_html(i, env)))),
        p(HTML(fill(Q$explanation[i], env))),
        if (nzchar(worked))
          div(p(strong("Worked arithmetic"), style = "margin:10px 0 0 0;"),
              div(class = "worked", HTML(worked))),
        if (nzchar(rcode))
          div(p(strong("In R"), style = "margin:12px 0 0 0;"),
              tags$pre(class = "rcode", rcode))
      ))
    })

    # Check my answer
    observeEvent(input[[paste0("check_", sec)]], {
      i <- cur_index(sec)
      if (is.na(i)) return()
      id  <- Q$id[i]
      cnt <- count_of(id)
      key <- key_of(i, cnt)
      rid <- rid_of(i, cnt)
      env <- item_env(i, cnt + data_offset)
      type <- Q$type[i]
      status <- "incomplete"; msg <- ""; yours <- NULL

      if (type %in% c("mc", "tf")) {
        val <- input[[rid]]
        if (is.null(val) || !nzchar(val)) {
          msg <- "Choose an answer first, then tap Check my answer."
        } else {
          rv$resp[[key]] <- val
          correct <- if (type == "mc") val == trimws(Q$answer[i]) else
            substr(tolower(val), 1, 1) == substr(tolower(Q$answer[i]), 1, 1)
          status <- if (correct) "correct" else "incorrect"
        }
      } else if (type == "numeric") {
        target <- item_target(i, env)
        vals <- vapply(seq_along(target), function(k) {
          v <- input[[paste0(rid, "_", k)]]
          if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v)
        }, 0)
        if (any(is.na(vals))) {
          msg <- if (length(target) > 1) "Enter a number in every box, then tap Check my answer." else
            "Enter a number, then tap Check my answer."
        } else {
          rv$resp[[key]] <- vals
          tol <- item_tol(i, target)
          status <- if (all(abs(vals - target) <= tol + 1e-9)) "correct" else "incorrect"
          if (status == "incorrect") yours <- paste(fmt_num(vals), collapse = "; ")
        }
      } else if (type == "order") {
        n  <- length(split_sep(Q$choices[i]))
        pk <- rv$picks[[key]]
        if (length(pk) < n) {
          msg <- "Tap all of the steps in order, then tap Check my answer."
        } else {
          status <- if (identical(as.integer(pk), seq_len(n))) "correct" else "incorrect"
        }
      }

      rv$fb[[key]] <- list(status = status, msg = msg, yours = yours)
      if (status != "incomplete" && is.null(rv$first[[id]]))
        rv$first[[id]] <- (status == "correct")
    })

    observeEvent(input[[paste0("prev_", sec)]], {
      if (rv$pos[[sec]] > 1) rv$pos[[sec]] <- rv$pos[[sec]] - 1L
    })
    observeEvent(input[[paste0("next_", sec)]], {
      if (rv$pos[[sec]] < length(rv$set[[sec]])) rv$pos[[sec]] <- rv$pos[[sec]] + 1L
    })
  })

  # ---------------- taps from dots, steps and small buttons -----------------
  observeEvent(input$evt, {
    e   <- input$evt
    sec <- e$s
    if (is.null(sec) || !(sec %in% names(sections))) return()
    k <- as.integer(e$k)
    if (e$a == "jump") {
      if (k >= 1 && k <= length(rv$set[[sec]])) rv$pos[[sec]] <- k
      return()
    }
    if (e$a == "goto") {
      # k is a row of questions.csv; add it to the current set if needed
      if (k >= 1 && k <= nrow(Q) && Q$section[k] == sec) {
        st <- rv$set[[sec]]
        if (!(k %in% st)) { st <- sort(c(st, k)); rv$set[[sec]] <- st }
        rv$pos[[sec]] <- match(k, st)
      }
      updateTabsetPanel(session, "tabs", selected = sec)
      return()
    }
    if (e$a == "newset") {
      rv$set[[sec]] <- draw_set(sec, tried_ids = names(rv$first))
      rv$pos[[sec]] <- 1L
      return()
    }
    i <- cur_index(sec)
    if (is.na(i)) return()
    id  <- Q$id[i]
    cnt <- count_of(id)
    key <- key_of(i, cnt)
    if (e$a == "new") {
      rv$count[[id]] <- cnt + 1L
    } else if (e$a == "pick") {
      pk <- rv$picks[[key]]
      if (!(k %in% pk)) rv$picks[[key]] <- c(pk, k)
      rv$fb[[key]] <- NULL
    } else if (e$a == "undo") {
      pk <- rv$picks[[key]]
      if (length(pk) > 0) rv$picks[[key]] <- pk[-length(pk)]
      rv$fb[[key]] <- NULL
    } else if (e$a == "clear") {
      rv$picks[[key]] <- integer(0)
      rv$fb[[key]] <- NULL
    }
  })

  # ---------------- summary ---------------------------------------------------
  output$summary <- renderUI({
    first <- rv$first
    rows_html <- lapply(names(sections), function(sec) {
      ids <- Q$id[sec_rows[[sec]]]
      res <- lapply(ids, function(id) first[[id]])
      tried <- sum(!vapply(res, is.null, TRUE))
      right <- sum(vapply(res, function(r) isTRUE(r), TRUE))
      tags$tr(tags$td(sections[[sec]]),
              tags$td(paste(tried, "of", length(ids))),
              tags$td(paste(right, "of", tried)))
    })
    skill_html <- lapply(names(skills), function(sk) {
      ids <- Q$id[Q$skill == sk]
      if (length(ids) == 0) return(NULL)
      res <- lapply(ids, function(id) first[[id]])
      tried <- sum(!vapply(res, is.null, TRUE))
      right <- sum(vapply(res, function(r) isTRUE(r), TRUE))
      tags$tr(tags$td(skills[[sk]]),
              tags$td(paste(tried, "of", length(ids))),
              tags$td(paste(right, "of", tried)))
    })
    revisit <- unlist(lapply(names(sections), function(sec) {
      rows <- sec_rows[[sec]]
      lapply(seq_along(rows), function(k) {
        if (isFALSE(first[[Q$id[rows[k]]]]))
          tags$li(tags$span(class = "revisit", onclick = js_evt("goto", sec, rows[k]),
                            paste0(sections[[sec]], ", question ", Q$id[rows[k]])),
                  span(style = "color:#777;",
                       if (Q$skill[rows[k]] %in% names(skills))
                         paste0(" (", skills[[Q$skill[rows[k]]]], ")")))
      })
    }), recursive = FALSE)
    revisit <- Filter(Negate(is.null), revisit)

    n_tried <- length(first)
    tagList(
      p(style = "font-size:17px; line-height:1.6;",
        paste0("You have tried ", n_tried, " of the ", nrow(Q),
               " questions in the bank. These counts use your first try at ",
               "each question only.")),
      tags$table(class = "sumtab",
                 tags$tr(tags$th("By section"), tags$th("Tried"),
                         tags$th("Right on the first try")),
                 rows_html),
      h4(style = paste0("color:", teal, ";"), "By skill"),
      tags$table(class = "sumtab",
                 tags$tr(tags$th("Skill"), tags$th("Tried"),
                         tags$th("Right on the first try")),
                 skill_html),
      if (length(revisit) > 0)
        tagList(h4(style = paste0("color:", orange, ";"), "Worth another look"),
                p("Tap an item to go straight to it."),
                tags$ul(style = "font-size:17px; line-height:1.9;", revisit))
      else if (n_tried > 0)
        p(style = paste0("font-size:17px; color:", teal, ";"),
          "Nothing to revisit so far. Nicely done.")
    )
  })

  observeEvent(input$reset_all, {
    rv$set <- all_sets(); rv$pos <- blank_pos(); rv$count <- list(); rv$first <- list()
    rv$fb <- list(); rv$resp <- list(); rv$picks <- list()
  })
}

# ---- launch -----------------------------------------------------------------
shinyApp(ui = ui, server = server)
