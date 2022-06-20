\NeedsTeXFormat{LaTeX2e} % we need to have LaTeX2e for this to compile 
\ProvidesClass{reportclass}[2021/10/22] % reportclass is the name to use this class 

%%%%
% Title Commands
%%%%
\newcommand{\professor}[1]{ \newcommand{\professorloc}{#1} }
\newcommand{\class}[1]{ \newcommand{\classloc}{#1} }
\newcommand{\institute}[1]{ \newcommand{\instituteloc}{#1} }
\newcommand{\department}[1]{ \newcommand{\departmentloc}{#1} }
\newcommand{\logo}[1]{ \newcommand{\logoloc}{#1} }

%%%%
% Page Format
%%%%
\DeclareOption{twocolumn}{\OptionNotUsed}
\DeclareOption{twoside}{\OptionNotUsed}
\PassOptionsToClass{a4paper}{article}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions{\relax}

\global\let\thanks\relax
\global\let\@thanks\@empty

\LoadClass{article}

%%%%
% Packages
%%%%
\RequirePackage{config/requirepackages}
\RequirePackage{config/title}
\RequirePackage{config/configuration}

\endinput
