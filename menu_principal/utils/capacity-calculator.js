/**
 * Capacity Calculator - Sistema de Cálculo de Capacidade de Campanhas
 *
 * Regras de negócio:
 * - 75 ligações por hora por linha
 * - 600 ligações por dia por linha (8 horas comerciais)
 * - Horário comercial: 08:00 - 18:00
 * - Intervalos de 30 minutos para arredondamento
 */

// ==================== CONSTANTES ====================

const CALLS_PER_HOUR_PER_LINE = 75;
const COMMERCIAL_HOURS = 8;
const CALLS_PER_DAY_PER_LINE = CALLS_PER_HOUR_PER_LINE * COMMERCIAL_HOURS; // 600
const COMMERCIAL_START = "08:00";
const COMMERCIAL_END = "18:00";
const INTERVAL_MINUTES = 30;

// ==================== FUNÇÕES DE CÁLCULO ====================

/**
 * Calcula a capacidade horária com base no número de linhas
 * @param {number} numeroLinhas - Número de linhas disponíveis
 * @returns {number} Ligações por hora
 */
function calculateHourlyCapacity(numeroLinhas) {
    return numeroLinhas * CALLS_PER_HOUR_PER_LINE;
}

/**
 * Calcula a capacidade diária com base no número de linhas
 * @param {number} numeroLinhas - Número de linhas disponíveis
 * @returns {number} Ligações por dia
 */
function calculateDailyCapacity(numeroLinhas) {
    return numeroLinhas * CALLS_PER_DAY_PER_LINE;
}

/**
 * Calcula a duração estimada da campanha em minutos
 * @param {number} numLeads - Número de leads
 * @param {number} numeroLinhas - Número de linhas disponíveis
 * @returns {number} Duração em minutos
 */
function calculateCampaignDuration(numLeads, numeroLinhas) {
    const hourlyCapacity = calculateHourlyCapacity(numeroLinhas);
    const horasCompletas = Math.floor(numLeads / hourlyCapacity);
    const leadsRestantes = numLeads % hourlyCapacity;

    // Calcula minutos para os leads restantes (arredonda para cima em intervalos de 30min)
    const minutosRestantes = leadsRestantes > 0
        ? Math.ceil((leadsRestantes / hourlyCapacity) * 60 / INTERVAL_MINUTES) * INTERVAL_MINUTES
        : 0;

    return (horasCompletas * 60) + minutosRestantes;
}

/**
 * Adiciona minutos a um horário
 * @param {string} time - Horário no formato "HH:MM"
 * @param {number} minutes - Minutos a adicionar
 * @returns {string} Novo horário no formato "HH:MM"
 */
function addMinutes(time, minutes) {
    const [hours, mins] = time.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, mins + minutes, 0, 0);

    const newHours = String(date.getHours()).padStart(2, '0');
    const newMins = String(date.getMinutes()).padStart(2, '0');

    return `${newHours}:${newMins}`;
}

/**
 * Calcula o horário de término da campanha
 * @param {string} startTime - Horário de início "HH:MM"
 * @param {number} durationMinutes - Duração em minutos
 * @returns {string} Horário de término "HH:MM"
 */
function calculateEndTime(startTime, durationMinutes) {
    return addMinutes(startTime, durationMinutes);
}

/**
 * Formata duração em minutos para formato legível
 * @param {number} minutes - Duração em minutos
 * @returns {string} Formato "Xh Ymin"
 */
function formatDuration(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    if (hours === 0) {
        return `${mins}min`;
    } else if (mins === 0) {
        return `${hours}h`;
    } else {
        return `${hours}h ${mins}min`;
    }
}

/**
 * Verifica se um horário está dentro do horário comercial
 * @param {string} time - Horário no formato "HH:MM"
 * @returns {boolean} True se dentro do horário comercial
 */
function isCommercialTime(time) {
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;

    const [startHours, startMins] = COMMERCIAL_START.split(':').map(Number);
    const startInMinutes = startHours * 60 + startMins;

    const [endHours, endMins] = COMMERCIAL_END.split(':').map(Number);
    const endInMinutes = endHours * 60 + endMins;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
}

/**
 * Gera timeline de intervalos de 30 minutos para a campanha
 * @param {number} numLeads - Número de leads
 * @param {string} startTime - Horário de início "HH:MM"
 * @param {number} numeroLinhas - Número de linhas disponíveis
 * @returns {Array} Array de objetos com intervalos
 */
function generateTimeline(numLeads, startTime, numeroLinhas) {
    const hourlyCapacity = calculateHourlyCapacity(numeroLinhas);
    const halfHourCapacity = Math.floor(hourlyCapacity / 2);

    const intervalos = [];
    let leadsRestantes = numLeads;
    let currentTime = startTime;

    while (leadsRestantes > 0) {
        const ligacoesIntervalo = Math.min(leadsRestantes, halfHourCapacity);
        const endTime = addMinutes(currentTime, INTERVAL_MINUTES);

        intervalos.push({
            inicio: currentTime,
            fim: endTime,
            ligacoes: ligacoesIntervalo,
            isPartial: ligacoesIntervalo < halfHourCapacity,
            isFull: ligacoesIntervalo === halfHourCapacity
        });

        leadsRestantes -= ligacoesIntervalo;
        currentTime = endTime;
    }

    return intervalos;
}

/**
 * Agrupa intervalos de 30min em blocos de 1 hora
 * @param {Array} intervalos - Array de intervalos de 30min
 * @returns {Array} Array de blocos de 1 hora
 */
function groupIntervalsToHours(intervalos) {
    const hoursBlocks = [];

    for (let i = 0; i < intervalos.length; i += 2) {
        const first = intervalos[i];
        const second = intervalos[i + 1];

        if (second) {
            // Bloco completo de 1 hora
            hoursBlocks.push({
                inicio: first.inicio,
                fim: second.fim,
                ligacoes: first.ligacoes + second.ligacoes,
                isFull: first.isFull && second.isFull
            });
        } else {
            // Último intervalo (menos de 1 hora)
            hoursBlocks.push({
                inicio: first.inicio,
                fim: first.fim,
                ligacoes: first.ligacoes,
                isFull: false,
                isPartial: true
            });
        }
    }

    return hoursBlocks;
}

/**
 * Valida se é possível agendar a campanha
 * @param {number} numLeads - Número de leads
 * @param {string} startTime - Horário de início
 * @param {number} numeroLinhas - Número de linhas
 * @returns {Object} { valid: boolean, error: string }
 */
function validateCampaign(numLeads, startTime, numeroLinhas) {
    // Valida capacidade diária
    const dailyCapacity = calculateDailyCapacity(numeroLinhas);
    if (numLeads > dailyCapacity) {
        return {
            valid: false,
            error: `LIMIT_EXCEEDED`,
            maxLeads: dailyCapacity,
            attemptedLeads: numLeads
        };
    }

    // Valida horário de início
    if (!isCommercialTime(startTime)) {
        return {
            valid: false,
            error: `INVALID_START_TIME`,
            commercialStart: COMMERCIAL_START,
            commercialEnd: COMMERCIAL_END
        };
    }

    // Valida horário de término
    const duration = calculateCampaignDuration(numLeads, numeroLinhas);
    const endTime = calculateEndTime(startTime, duration);

    if (!isCommercialTime(endTime) || endTime > COMMERCIAL_END) {
        return {
            valid: false,
            error: `INVALID_TIMEFRAME`,
            endTime: endTime,
            commercialEnd: COMMERCIAL_END
        };
    }

    return { valid: true };
}

/**
 * Busca dados do plano do usuário do localStorage
 * @returns {Object} Dados do plano
 */
function getUserPlanData() {
    const numeroLinhas = parseInt(localStorage.getItem('numero_linhas') || '0');
    const ligacoesPorHora = calculateHourlyCapacity(numeroLinhas);
    const ligacoesDiarias = calculateDailyCapacity(numeroLinhas);

    return {
        numeroLinhas,
        ligacoesPorHora,
        ligacoesDiarias
    };
}

/**
 * Formata número com separador de milhares
 * @param {number} num - Número a formatar
 * @returns {string} Número formatado
 */
function formatNumber(num) {
    return num.toLocaleString('pt-BR');
}

/**
 * Gera horários disponíveis para início de campanha (intervalos de 30min)
 * @returns {Array} Array de horários no formato "HH:MM"
 */
function getAvailableStartTimes() {
    const times = [];
    const [startHour] = COMMERCIAL_START.split(':').map(Number);
    const [endHour] = COMMERCIAL_END.split(':').map(Number);

    for (let hour = startHour; hour < endHour; hour++) {
        times.push(`${String(hour).padStart(2, '0')}:00`);
        times.push(`${String(hour).padStart(2, '0')}:30`);
    }

    return times;
}

/**
 * Obtém a data mínima para agendamento (hoje)
 * @returns {string} Data no formato "YYYY-MM-DD"
 */
function getMinScheduleDate() {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
}

/**
 * Formata data para exibição em português
 * @param {string} dateString - Data no formato "YYYY-MM-DD"
 * @returns {string} Data formatada "DD/MM/YYYY"
 */
function formatDate(dateString) {
    const [year, month, day] = dateString.split('-');
    return `${day}/${month}/${year}`;
}

// ==================== EXPORTAÇÃO (para uso como módulo) ====================

// Se estiver usando módulos ES6, descomente:
// export {
//     calculateHourlyCapacity,
//     calculateDailyCapacity,
//     calculateCampaignDuration,
//     calculateEndTime,
//     formatDuration,
//     generateTimeline,
//     groupIntervalsToHours,
//     validateCampaign,
//     getUserPlanData,
//     formatNumber,
//     getAvailableStartTimes,
//     getMinScheduleDate,
//     formatDate,
//     isCommercialTime,
//     addMinutes,
//     CALLS_PER_HOUR_PER_LINE,
//     CALLS_PER_DAY_PER_LINE,
//     COMMERCIAL_START,
//     COMMERCIAL_END
// };

console.log('✅ Capacity Calculator carregado com sucesso');
