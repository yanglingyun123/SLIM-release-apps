function [f g H] = misfit_uq_slowness3(m,D,Q,model,params);

%% function of the misfit for the uncertainty quantification
% Use : [f g H] = misfit_uq_slowness(m,D,Q,model,params);
% Input :
% m - model
% D - Data
% Q - Source
% model - model parameters
% params - computing parameters
%
% Output:
% f  - misfit function
% g  - gradient
% H  - Hessian
%
% Author : Zhilong Fang
% Date   : 2016/01

sigma           = model.sigma;
beta            = model.beta;
sigma_p         = model.sigma_p;
delta_bdy      = model.delta_bdy;
%for i = 1:length(model.freq)
 %   params.lambda(i) = params.lambda(i) * sigma(i);
%end

fh      = misfit_setup(Q,D,model,params);

if ~isfield(model,'flagPriorVel')
    flagPriorVel = 0;
else
    flagPriorVel = model.flagPriorVel;
end

switch model.PriorType
    case 'nonsmooth'
        if flagPriorVel < 1
            fhp     = @(x) misfit_prior_nosmth(x, sigma_p, model.n);
        else
            fhp     = @(x) misfit_prior_nosmth_vel(x, sigma_p, model.n);
        end
    case 'smooth'
        if flagPriorVel < 1
            fhp     = @(x) misfit_prior_smth(x, sigma_p, model.n, delta_bdy);
        else
            fhp     = @(x) misfit_prior_smth_vel2(x, model.mp(:), sigma_p, model.n, delta_bdy);
        end
    case 'TV'
        if flagPriorVel < 1
            fhp     = @(x) misfit_prior_TV(x, sigma_p, model.n);
        else
            fhp     = @(x) misfit_prior_TV_vel(x, sigma_p, model.n);
        end
    otherwise
        error('Wrong model.PriorType, please select one of the following types: nonsmooth, smooth, TV');
end

[fmis gmis Hmis] = fh(m(:));

if flagPriorVel > 0
        [fpr gpr Hpr]    = fhp(m(:));
else
        [fpr gpr Hpr]    = fhp(m(:)- vec(model.mp(:)));
end



f    = fmis + beta * fpr;
g    = gmis + beta * gpr;
H    = Hmis + beta * Hpr;

if model.Priormp > 0
    if isfield(model,'velprior')
        velprior = model.velprior;
    else
        velprior = 0;
    end
    if velprior == 0
        mp       = model.mp;
        ISIGMA_mp = model.SIGMAp;
        fhpm     = @(x) misfit_prior_mp2(x,mp,ISIGMA_mp);
        [fpm gpm Hpm] = fhpm(m(:));
    else
        mp_v       = model.mp;
        %mp_v     = 1./sqrt(mp);
        ISIGMA_mp = model.SIGMAp;
        fhpm     = @(x) misfit_prior_mp2(x,mp_v,ISIGMA_mp);
        dfv      = @(x) -0.5 * x(:).^(-1.5);
        Jv       = opDiag(dfv(m(:)));
        
        [fpm gpm Hpm] = fhpm(1./sqrt(m(:)));
        gpm           = Jv' * gpm;
        Hpm           = Jv' * Hpm * Jv + opDiag(gpm) * opDiag(3/4 * m(:).^(-2.5));
    end
    f        = f + fpm;
    g        = g + gpm;
    H        = H + Hpm;
end









