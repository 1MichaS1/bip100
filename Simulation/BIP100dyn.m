%---------------------------------------------------------------------------------------------------
% Simulation for FreeMat v4.0 (Matlab clone with GPLv2 license)
% Download for all operating systems: http://freemat.sourceforge.net/download.html
%
% Purpose of this file:
%        Show and illustrate how a dynamic block size limit (BSL) growth combined with a voting
%        mechanism similar to (but enhanced compared to) BIP100 plays out.
%
% Votes: This simulation relates to a new BIP. According to this BIP, certain vote majorities
%        (60% or 80%) allow for certain pre-defined maximum adjustment steps (in %).
%        This simulation assumes that in case that such a 60% or 80% vote majority occurs, the
%        BSL adjustmen done is actually the maximum adjustment that is possible for this voting
%        majority.
%        This is done for the sake of simplicity and to investigate how the most extreme behaviour
%        would look like.
%
% Note: This simulation assumes 52 weeks == 1 year for simplicity (the error is 1.25 days or 0.34%).
%       This simulation assumes that 2 weeks = 2016 blocks.
%       Since hash rate is expected to increase long-term, be it alone due to the advances in
%       technology, reality is expected to show that 2016 blocks < 2 week.
%       This can be accounted for by setting 'time_stretch_factor' accordingly.
%
%       (C) 2015 by Michael_S - This code is released to the public domain.
%           (1MichaS16UMKFgNjanKrtfD51HpBkqPAwD)
%
%---------------------------------------------------------------------------------------------------
close all; clear all;

%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%% #0 - Parameter Settings:

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% #0.1 - Algorithm Parameters:

BSL_init_MB = 1;% Initial value of the block size limit

adj_interval_wk = 2;% =2: Keep this =2: BSL changes every 2 weeks

% (Maximum) Percentage by which BSL changes after every 2 weeks:
% Original BIP100 settings (as of 7 Sept 2015):
step_incr_def   = 0.0; % =0.0%, i.e. in case of "neutral/no voting", BSL stays the same.
step_incr_small = 0.0; % +/- 0.0% (for 60% majority vote)
step_incr_big   = 20; % +/- 20.0% (for 80% majority vote) =  +11300% p.a. (factor x114, maximum)
% Proposed modified settings:
step_incr_def   = 1.09; %   +1.09% (in case of "no vote")  =   +32.5% p.a. (factor x1.325)
step_incr_small = 1.60; % +/-1.60% (for 60% majority vote) =   +51.0% p.a. (factor x1.51)
step_incr_big   = 10.0; % +/-10.0% (for 80% majority vote) = +1100.0% p.a. (factor x12, maximum)

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% #0.2 - Simulation Parameters: Time Range:

Start_Year = 2016 + 0*1/12;% e.g. 2016.5 means 1st July 2016

NbYrs=10; % Simulate for this number of years (1008*52 blocks == 52 weeks == 1 year)

% If block times are shorter than 10 min, enter corresponding factor <1.0 here. Or vice versa:
time_stretch_factor = 1.0;%[1.0] e.g. 0.9 means 9 min avg. block time

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% #0.3 - Simulation Parameters: Configuration of Voting Events:

% Probabilities of random events (different for every re-run of the simulation):
prob_80_up   = 0.0;% probability that a big up-adjustment   occurs thanks to a 80% vote majority
prob_80_down = 0.0;% probability that big down-adjustment   occurs thanks to a 80% vote majority
prob_60_up   = 0.0;% probability that a small up-adjustment occurs thanks to a 60% vote majority
prob_60_down = 0.0;% probability that small down-adjustment occurs thanks to a 60% vote majority

% Systematic voting events: 
% Pattern: 0 = default 'no vote', +/-1 = small step, +/-2 = big step. Pattern repeats cyclically
% (In this simulation a pattern value <>0 overrules a probability-determined value from above)
pattern = [0  0 0 0 1 0 0 0 0 1 ...
           0  0 0 0 1 0 0 0 0 1 ...
           0  0 0 0 1 0 0 0 0 2 ...
           0  0 0 0 1 0 0 0 0 1 ...
           0  0 0 0 1 0 0 0 0 1 ];
%pattern = [0 -1 0 0 -1 0 0 0 0 -1 ...
%           0 -1 0 0 -1 0 0 0 0 -1 ...
%           0 -1 0 0 -1 0 0 0 0 -1 ...
%           0 -1 0 0 -1 0 0 0 0 -1 ...
%           0 -1 0 0 -1 0 0 0 0 -1 ];
%pattern = [0 0 0 0 0 0 0 0 0 0 ...
%           0 2 0 0 0 0 0 0 0 0 ...
%           0 0 0 0 0 0 0 0 0 0 ...
%           0 0 0 0 0 2 0 0 0 0 ...
%           0 0 0 0 0 0 0 0 0 0 ];
%pattern = [0];

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% #0.4 - Parameters to Illustrate Simulation Results Appealingly:

% Plot Figure Window Size - modify in dependence of your screen resolution:
plot_window_width  = 900;
plot_window_height = 360;
plot_window_width_histogr  = 630;
plot_window_height_histogr = 504;

% Some reference curves are drawn into the diagrams, for comparison:
% Yearly growth of technology:
nielsen_growth = 50.000;% Steady 50% p.a. growth of internet bandwidth 1983..2014 acc. to
                        % Nielsen's law: "http://www.nngroup.com/articles/law-of-bandwidth"
bip101_growth  = 41.421;% 41.421% p.a. growth acc. to Gavin Andresen's BIP101 proposal.
wuille_growth  = 17.700;% 17.7% p.a. growth acc. to Pieter Wuille's "BIP?? proposal".

%---------------------------------------------------------------------------------------------------
%----------------------------- Do Not Change Anything Below This Line! -----------------------------
%---------------------------------------------------------------------------------------------------
%% #1 - Initializations:

time = [0:1:52/adj_interval_wk*NbYrs];% one time index == 'adj_interval_wk' weeks.

step_factor_def     = 1+step_incr_def/100;
step_factor_nielsen = (1+nielsen_growth/100)^(1/(52/adj_interval_wk));
step_factor_bip101  = (1+bip101_growth/100)^(1/(52/adj_interval_wk));
step_factor_wuille  = (1+wuille_growth/100)^(1/(52/adj_interval_wk));

% Parameter consistency checks:
if prob_80_up >= prob_60_up && prob_60_up > 0,
    disp('ERROR: Invalid parameter setting: "prob_80_up >= prob_60_up" is not allowed!');
    return
end
if prob_80_down >= prob_60_down && prob_60_down > 0,
    disp('ERROR: Invalid parameter setting: "prob_80_down >= prob_60_down" is not allowed!');
    return
end

if prob_60_up + prob_60_down > 1.0,
    disp('ERROR: Invalid parameter setting: "prob_60_up + prob_60_down" must be <= 1.0 !');
    return
end

if adj_interval_wk ~= 1 && adj_interval_wk ~= 2 && adj_interval_wk ~= 4 ...
   && adj_interval_wk ~= 13 && adj_interval_wk ~= 26 && adj_interval_wk ~= 52,
    disp('ERROR: Invalid parameter setting: "adj_interval_wk" must be one of 1, 2, 4, 13, 26, 52.');
    return
end

%---------------------------------------------------------------------------------------------------
%% #2 - The Simulation:

% Initialize vectors capturing the BSL per tick (1 tick = 2 weeks by default acc. to adj_interval_wk)
BSL         = nan*ones(1,length(time));
BSL(1)      = BSL_init_MB;
BSL_def     = BSL;
BSL_nielsen = BSL;
BSL_bip101  = BSL;
BSL_wuille  = BSL;

EVENT_KIND = nan*ones(1,length(time));% Memorise what kind of voting event took place for adjustment.

pattern_idx=0;
for k = 2:(time(end)+1),
    % what is the event: big up, big down, small up, small down, or default?
    event = rand();
    if event < prob_80_up;
        step_factor = 1+step_incr_big/100; EVENT_KIND(k) = +2;
    elseif event < prob_60_up;
        step_factor = 1+step_incr_small/100; EVENT_KIND(k) = +1;
    elseif event > 1-prob_80_down;
        step_factor = (100-step_incr_big)/100; EVENT_KIND(k) = -2;
    elseif event > 1-prob_60_down;
        step_factor = (100-step_incr_small)/100; EVENT_KIND(k) = -1;
    else
        step_factor = step_factor_def; EVENT_KIND(k) = 0;% step_factor = 1+step_incr_def/100
    end
    pattern_idx = 1+mod(pattern_idx, length(pattern));
    if pattern(pattern_idx) == +2;
        step_factor = 1+step_incr_big/100; EVENT_KIND(k) = +2;
    elseif pattern(pattern_idx) == +1;
        step_factor = 1+step_incr_small/100; EVENT_KIND(k) = +1;
    elseif pattern(pattern_idx) == -2;
        step_factor = (100-step_incr_big)/100; EVENT_KIND(k) = -2;
    elseif pattern(pattern_idx) == -1;
        step_factor = (100-step_incr_small)/100; EVENT_KIND(k) = -1;
    end
    BSL(k)         = BSL(k-1)         * step_factor;
    BSL_def(k)     = BSL_def(k-1)     * step_factor_def;
    BSL_nielsen(k) = BSL_nielsen(k-1) * step_factor_nielsen;
    BSL_bip101(k)  = BSL_bip101(k-1)  * step_factor_bip101;
    BSL_wuille(k)  = BSL_wuille(k-1)  * step_factor_wuille;
end


%---------------------------------------------------------------------------------------------------
%% #3 - Post-Processing & Display:


% Yearly average percentage change of BSL since the start:

% Years, without the first year of course:
years_tmp = ((52/adj_interval_wk-1)+[1:length(BSL((52/adj_interval_wk+1):end))]) ...
            / (52/adj_interval_wk);


factor_tmp = (BSL_def((52/adj_interval_wk+1):end)/BSL_def(1)).^( 1./years_tmp );
BSL_def_percent_change_avg = 100*(factor_tmp-1);

factor_tmp = (BSL_nielsen((52/adj_interval_wk+1):end)/BSL_nielsen(1)).^( 1./years_tmp );
BSL_nielsen_percent_change_avg = 100*(factor_tmp-1);

factor_tmp = (BSL_bip101((52/adj_interval_wk+1):end)/BSL_bip101(1)).^( 1./years_tmp );
BSL_bip101_percent_change_avg = 100*(factor_tmp-1);

factor_tmp = (BSL_wuille((52/adj_interval_wk+1):end)/BSL_wuille(1)).^( 1./years_tmp );
BSL_wuille_percent_change_avg = 100*(factor_tmp-1);

factor_tmp = (BSL((52/adj_interval_wk+1):end)/BSL(1)).^( 1./years_tmp );
BSL_percent_change_avg = 100*(factor_tmp-1);



% ---------- Plot 1 : Block Size Limit ----------
figure;
hold on;
plot(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_nielsen,'m-','linewidth',1);
plot(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_bip101,'g-','linewidth',1);
plot(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_def,'b:','linewidth',6);
plot(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_wuille,'c-','linewidth',1);
plot(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL    ,'r-','linewidth',2);
grid on;
a=axis;
axis([Start_Year Start_Year+NbYrs*time_stretch_factor 0 a(4)]);
xlabel('Year')
ylabel('Block Size Limit [MB]')
title(['Block Size Limit vs. Time'])
tmpStrDef=['BSL new BIP w/o votes, ',num2str((step_factor_def^(52/adj_interval_wk)-1)*100,'%0.1f'),'% p.a.'];
legend(...
       'Nielsen, 50% p.a.',...
       'BIP101, 41.4% p.a.',...
       tmpStrDef,...
       'Wuille, 17.7% p.a.',...
       'Real BSL new BIP',...
       'location','northwest');
sizefig(plot_window_width,plot_window_height)


% ---------- Plot 1b : Block Size Limit, logarithmic ----------
figure;
hold on;
semilogy(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_nielsen,'m-','linewidth',1);
semilogy(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_bip101,'g-','linewidth',1);
semilogy(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_def,'b:','linewidth',6);
semilogy(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL_wuille,'c-','linewidth',1);
semilogy(Start_Year+time/(52/adj_interval_wk)*time_stretch_factor, BSL    ,'r-','linewidth',2);
grid on;
a=axis;
axis([Start_Year Start_Year+NbYrs*time_stretch_factor a(3) a(4)]);
xlabel('Year')
ylabel('Block Size Limit [MB]')
title(['Block Size Limit vs. Time'])
tmpStrDef=['BSL new BIP w/o votes, ',num2str((step_factor_def^(52/adj_interval_wk)-1)*100,'%0.1f'),'% p.a.'];
legend(...
       'Nielsen, 50% p.a.',...
       'BIP101, 41.4% p.a.',...
       tmpStrDef,...
       'Wuille, 17.7% p.a.',...
       'Real BSL new BIP',...
       'location','northwest');
sizefig(plot_window_width,plot_window_height)


% ---------- Plot 2 : Block Size Limit Avg. Yearly Growth Rate ----------
figure;
hold on;
plot(Start_Year+time(1+52/adj_interval_wk:end)/...
                     (52/adj_interval_wk) * time_stretch_factor,BSL_nielsen_percent_change_avg, ...
    'm-','linewidth',1);
plot(Start_Year+time(1+52/adj_interval_wk:end)/...
                     (52/adj_interval_wk) * time_stretch_factor,BSL_bip101_percent_change_avg, ...
    'g-','linewidth',1);
plot(Start_Year+time(1+52/adj_interval_wk:end)/...
                     (52/adj_interval_wk) * time_stretch_factor,BSL_def_percent_change_avg, ...
    'b:','linewidth',6);
plot(Start_Year+time(1+52/adj_interval_wk:end)/...
                     (52/adj_interval_wk) * time_stretch_factor,BSL_wuille_percent_change_avg, ...
    'c-','linewidth',1);
plot(Start_Year+time(1+52/adj_interval_wk:end)/...
                     (52/adj_interval_wk) * time_stretch_factor,BSL_percent_change_avg, ...
    'r-','linewidth',2);
grid on;
a=axis;
axis([Start_Year Start_Year+NbYrs*time_stretch_factor 0 max(80,a(4))]);
xlabel('Year')
ylabel('BSL avg. yearly change [%]')
title(['Yearly Avg. Block Size Limit Change Rate Since Year ',num2str(Start_Year,'%0.2f')])
tmpStrDef=['BSL new BIP w/o votes, ',num2str((step_factor_def^(52/adj_interval_wk)-1)*100,'%0.1f'),'% p.a.'];
if 0,
    legend(...
       'Nielsen, 50% p.a.',...
       'BIP101, 41.4% p.a.',...
       tmpStrDef,...
       'Wuille, 17.7% p.a.',...
       'Real BSL new BIP',...
       'location','northwest');
end
sizefig(plot_window_width,plot_window_height)


% ---------- Plot 3 : Event Histogram ----------
figure;
occurence=hist(EVENT_KIND+3, [1,2,3,4,5]);
hist(EVENT_KIND+3, [1,2,3,4,5]);
set(gca,'XTick', [1 2 3 4 5])
set(gca,'XTickLabel', '80% down|60% down|"no vote"|60% up|80% up')
title(['Statistics from ', num2str(length(EVENT_KIND)-1), ...
       ' BSL-Adjustments (Corresponding Adjustments-Steps in %)'])
ylabel(['Number of Adjustments (once every ',num2str(adj_interval_wk*1008,'%0.0f'),' blocks)'])
xlabel('Kind of voting majority occuring for BSL adjustment up/down')
a=axis;
axis([a(1) a(2) a(3) a(4)*1.2]);
sizefig(plot_window_width_histogr,plot_window_height_histogr);

% Write the percentage step sizes of BSL adjustments into the diagram:
xoffset=-0.37;
yoffset=0.1*(a(4)*1.2);
text(1+xoffset,occurence(1)+yoffset,['(-',num2str(step_incr_big,'%0.1f'),'% down)']);
text(2+xoffset,occurence(2)+yoffset,['(-',num2str(step_incr_small,'%0.1f'),'% down)']);
text(3+xoffset,occurence(3)+yoffset,[' (+',num2str(step_incr_def,'%0.1f'),'%)']);
text(4+xoffset,occurence(4)+yoffset,['(+',num2str(step_incr_small,'%0.1f'),'% up)']);
text(5+xoffset,occurence(5)+yoffset,['(+',num2str(step_incr_big,'%0.1f'),'% up)']);

% Write the values of the heights of the histogram bars (in percent) into the diagram:
percentage = occurence/sum(occurence)*100;
xoffset=-0.15;
yoffset=0.05*(a(4)*1.2);
text(1+xoffset,occurence(1)+yoffset,[num2str(percentage(1),'%0.1f'),'%']);
text(2+xoffset,occurence(2)+yoffset,[num2str(percentage(2),'%0.1f'),'%']);
text(3+xoffset,occurence(3)+yoffset,[num2str(percentage(3),'%0.1f'),'%']);
text(4+xoffset,occurence(4)+yoffset,[num2str(percentage(4),'%0.1f'),'%']);
text(5+xoffset,occurence(5)+yoffset,[num2str(percentage(5),'%0.1f'),'%']);
