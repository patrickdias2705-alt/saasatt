/**
 * Timeline Renderer - Sistema de Renderização Visual da Timeline de Campanhas
 *
 * Responsável por criar a visualização estilo "merge cells" da grade de horários
 * Similar à grade de follow-up, mostrando intervalos de tempo
 */

// ==================== FUNÇÕES DE RENDERIZAÇÃO ====================

/**
 * Renderiza a timeline completa na tabela estilo grade de horários
 * @param {Array} intervalos - Array de intervalos gerados pelo capacity-calculator
 * @param {string} containerId - ID do elemento tbody da tabela
 */
function renderTimeline(intervalos, containerId = 'timelineBody') {
    const tbody = document.getElementById(containerId);

    if (!tbody) {
        console.error(`Elemento ${containerId} não encontrado`);
        return;
    }

    // Limpa conteúdo anterior
    tbody.innerHTML = '';

    // Renderiza grade de horários estilo follow-up com merge cells
    renderMergedTimelineGrid(intervalos, tbody);

    console.log(`✅ Timeline renderizada estilo grade de horários`);
}

/**
 * Renderiza grade de horários com células mescladas
 * @param {Array} intervalos - Array de intervalos
 * @param {HTMLElement} tbody - Elemento tbody
 */
function renderMergedTimelineGrid(intervalos, tbody) {
    // Horário comercial: 08:00 - 18:00
    const allHours = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'];

    // Agrupa intervalos em blocos de 1 hora
    const blocos = groupIntervalsToHours(intervalos);

    // Calcula qual horário inicia e termina a campanha
    const startTime = blocos.length > 0 ? blocos[0].inicio : '08:00';
    const endTime = blocos.length > 0 ? blocos[blocos.length - 1].fim : '08:00';

    console.log('📊 Grade:', { startTime, endTime, blocos: blocos.length });

    // Cria mapa de ocupação por horário
    const ocupacaoMap = {};
    blocos.forEach(bloco => {
        const hora = bloco.inicio;
        ocupacaoMap[hora] = bloco;
    });

    let skipRows = 0;
    let isFirstOccupiedCell = true;

    allHours.forEach((hora, index) => {
        if (skipRows > 0) {
            skipRows--;
            return;
        }

        const tr = document.createElement('tr');
        tr.className = 'schedule-row';

        // Coluna de horário
        const tdTime = document.createElement('td');
        tdTime.className = 'time-cell-grid';
        tdTime.textContent = hora;
        tr.appendChild(tdTime);

        // Coluna de conteúdo
        const tdContent = document.createElement('td');
        tdContent.className = 'content-cell';

        // Verifica se este horário está ocupado
        const blocoOcupado = ocupacaoMap[hora];

        if (blocoOcupado) {
            // Calcula quantas linhas mesclar (rowspan)
            const horasOcupadas = blocos.filter(b => b.inicio >= hora && b.inicio < endTime).length;

            if (isFirstOccupiedCell) {
                tdContent.rowSpan = blocos.length;
                tdContent.className = 'content-cell occupied-cell';

                // Cria conteúdo visual da célula mesclada
                const occupiedBlock = createOccupiedBlock(blocos, startTime, endTime);
                tdContent.appendChild(occupiedBlock);

                skipRows = blocos.length - 1;
                isFirstOccupiedCell = false;
            }
        } else {
            // Célula vazia (sem atividade)
            tdContent.className = 'content-cell empty-cell';
            tdContent.innerHTML = '<span class="empty-label">Sem atividade</span>';
        }

        tr.appendChild(tdContent);
        tbody.appendChild(tr);
    });
}

/**
 * Cria bloco visual de horários ocupados
 * @param {Array} blocos - Blocos de horário
 * @param {string} startTime - Horário de início
 * @param {string} endTime - Horário de término
 * @returns {HTMLElement} Elemento div com conteúdo visual
 */
function createOccupiedBlock(blocos, startTime, endTime) {
    const container = document.createElement('div');
    container.className = 'occupied-block-container';

    // Header com informações principais
    const header = document.createElement('div');
    header.className = 'occupied-block-header';
    header.innerHTML = `
        <div class="block-title">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            Campanha em Execução
        </div>
        <div class="block-time">${startTime} - ${endTime}</div>
    `;
    container.appendChild(header);

    // Lista de horários com número de ligações
    const hoursList = document.createElement('div');
    hoursList.className = 'hours-list';

    blocos.forEach((bloco, index) => {
        const hourItem = document.createElement('div');
        hourItem.className = 'hour-item';
        hourItem.style.animationDelay = `${index * 0.05}s`;

        const isPartial = !bloco.isFull && bloco.ligacoes < (blocos[0]?.ligacoes || 0);

        hourItem.innerHTML = `
            <div class="hour-time">${bloco.inicio} - ${bloco.fim}</div>
            <div class="hour-calls ${isPartial ? 'partial' : 'full'}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
                </svg>
                ${formatNumber(bloco.ligacoes)} ligações
                ${isPartial ? '<span class="partial-badge">Parcial</span>' : ''}
            </div>
        `;

        hoursList.appendChild(hourItem);
    });

    container.appendChild(hoursList);

    // Footer com totais
    const totalCalls = blocos.reduce((sum, b) => sum + b.ligacoes, 0);
    const footer = document.createElement('div');
    footer.className = 'occupied-block-footer';
    footer.innerHTML = `
        <div class="footer-stat">
            <span class="stat-label">Total de Ligações:</span>
            <span class="stat-value">${formatNumber(totalCalls)}</span>
        </div>
        <div class="footer-stat">
            <span class="stat-label">Duração:</span>
            <span class="stat-value">${blocos.length}h</span>
        </div>
    `;
    container.appendChild(footer);

    return container;
}

/**
 * Cria uma linha da timeline
 * @param {Object} bloco - Objeto com dados do bloco de horário
 * @param {number} index - Índice do bloco
 * @returns {HTMLElement} Elemento tr
 */
function createTimelineRow(bloco, index) {
    const tr = document.createElement('tr');
    tr.className = 'timeline-row';

    if (bloco.isPartial) {
        tr.classList.add('partial-row');
    }

    // Coluna de horário
    const tdTime = document.createElement('td');
    tdTime.className = 'timeline-cell time-cell';
    tdTime.textContent = `${bloco.inicio} - ${bloco.fim}`;
    tr.appendChild(tdTime);

    // Coluna de ligações
    const tdCalls = document.createElement('td');
    tdCalls.className = 'timeline-cell calls-cell';
    tdCalls.textContent = formatNumber(bloco.ligacoes);
    tr.appendChild(tdCalls);

    // Coluna de status
    const tdStatus = document.createElement('td');
    tdStatus.className = 'timeline-cell status-cell';

    const statusBadge = document.createElement('span');
    statusBadge.className = 'status-badge';

    if (bloco.isFull) {
        statusBadge.classList.add('status-full');
        statusBadge.innerHTML = '🟢 Capacidade Total';
    } else if (bloco.isPartial) {
        statusBadge.classList.add('status-partial');
        statusBadge.innerHTML = '🟡 Parcial';
    } else {
        statusBadge.classList.add('status-active');
        statusBadge.innerHTML = '🟢 Ativo';
    }

    tdStatus.appendChild(statusBadge);
    tr.appendChild(tdStatus);

    // Animação de entrada
    tr.style.animation = `slideInRow 0.3s ease-out ${index * 0.05}s backwards`;

    return tr;
}

/**
 * Renderiza o resumo da campanha
 * @param {Object} summary - Objeto com dados do resumo
 */
function renderCampaignSummary(summary) {
    const {
        startTime,
        endTime,
        duration,
        totalLeads,
        hourlyCapacity,
        dailyCapacity
    } = summary;

    // Atualiza elementos do resumo
    updateElement('startTime', startTime);
    updateElement('endTime', endTime);
    updateElement('duration', formatDuration(duration));
    updateElement('totalLeadsDisplay', formatNumber(totalLeads));
    updateElement('hourlyCapacityDisplay', formatNumber(hourlyCapacity));

    console.log(`✅ Resumo da campanha renderizado`);
}

/**
 * Atualiza conteúdo de um elemento se existir
 * @param {string} elementId - ID do elemento
 * @param {string} content - Conteúdo a inserir
 */
function updateElement(elementId, content) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = content;
    }
}

/**
 * Renderiza o card de capacidade do plano
 * @param {Object} planData - Dados do plano
 * @param {number} uploadedLeads - Número de leads do upload
 */
function renderCapacityCard(planData, uploadedLeads) {
    const { numeroLinhas, ligacoesPorHora, ligacoesDiarias } = planData;

    updateElement('planLines', numeroLinhas);
    updateElement('planHourlyCapacity', formatNumber(ligacoesPorHora));
    updateElement('planDailyCapacity', formatNumber(ligacoesDiarias));
    updateElement('uploadedLeadsCount', formatNumber(uploadedLeads));

    // Atualiza barra de progresso
    const percentage = Math.min((uploadedLeads / ligacoesDiarias) * 100, 100);
    updateProgressBar('capacityProgressBar', percentage);

    // Atualiza status visual
    updateCapacityStatus(uploadedLeads, ligacoesDiarias);

    console.log(`✅ Card de capacidade renderizado (${uploadedLeads}/${ligacoesDiarias})`);
}

/**
 * Atualiza barra de progresso
 * @param {string} barId - ID da barra de progresso
 * @param {number} percentage - Percentual (0-100)
 */
function updateProgressBar(barId, percentage) {
    const progressBar = document.getElementById(barId);

    if (progressBar) {
        progressBar.style.width = `${percentage}%`;

        // Adiciona classes de cor baseado no percentual
        progressBar.classList.remove('progress-low', 'progress-medium', 'progress-high', 'progress-full');

        if (percentage >= 100) {
            progressBar.classList.add('progress-full');
        } else if (percentage >= 75) {
            progressBar.classList.add('progress-high');
        } else if (percentage >= 50) {
            progressBar.classList.add('progress-medium');
        } else {
            progressBar.classList.add('progress-low');
        }

        // Adiciona transição suave
        progressBar.style.transition = 'width 0.6s ease-out, background-color 0.3s ease';
    }
}

/**
 * Atualiza status visual de capacidade
 * @param {number} used - Capacidade usada
 * @param {number} total - Capacidade total
 */
function updateCapacityStatus(used, total) {
    const statusElement = document.getElementById('capacityStatus');

    if (statusElement) {
        const percentage = (used / total) * 100;

        statusElement.classList.remove('status-ok', 'status-warning', 'status-danger');

        if (used > total) {
            statusElement.classList.add('status-danger');
            statusElement.innerHTML = '❌ Limite excedido';
        } else if (percentage >= 90) {
            statusElement.classList.add('status-warning');
            statusElement.innerHTML = '⚠️ Próximo ao limite';
        } else {
            statusElement.classList.add('status-ok');
            statusElement.innerHTML = '✅ Dentro do limite';
        }
    }
}

/**
 * Mostra mensagem de erro de limite excedido
 * @param {number} maxLeads - Limite máximo
 * @param {number} attemptedLeads - Tentativa de leads
 */
function showLimitExceededError(maxLeads, attemptedLeads) {
    const errorHtml = `
        <div class="error-modal">
            <div class="error-content">
                <div class="error-icon">❌</div>
                <h2 class="error-title">Limite Excedido</h2>
                <p class="error-message">
                    Seu plano permite até <strong>${formatNumber(maxLeads)}</strong> ligações por dia.
                    <br>
                    Você tentou fazer upload de <strong>${formatNumber(attemptedLeads)}</strong> leads.
                </p>
                <div class="error-details">
                    <p>Para aumentar seu limite, entre em contato com o suporte:</p>
                    <a href="mailto:suporte@salesdever.io" class="support-link">
                        📧 suporte@salesdever.io
                    </a>
                </div>
                <button class="error-close-btn" onclick="closeLimitError()">
                    Entendi
                </button>
            </div>
        </div>
    `;

    // Adiciona modal ao body
    const modalContainer = document.createElement('div');
    modalContainer.id = 'limitErrorModal';
    modalContainer.className = 'error-modal-overlay';
    modalContainer.innerHTML = errorHtml;

    document.body.appendChild(modalContainer);

    // Mostra modal com animação
    setTimeout(() => {
        modalContainer.classList.add('active');
    }, 10);
}

/**
 * Fecha modal de erro de limite
 */
function closeLimitError() {
    const modal = document.getElementById('limitErrorModal');
    if (modal) {
        modal.classList.remove('active');
        setTimeout(() => {
            modal.remove();
        }, 300);
    }
}

/**
 * Mostra mensagem de erro de horário inválido
 * @param {string} endTime - Horário de término calculado
 * @param {string} commercialEnd - Horário limite comercial
 */
function showInvalidTimeframeError(endTime, commercialEnd) {
    const errorHtml = `
        <div class="error-modal">
            <div class="error-content">
                <div class="error-icon">⏰</div>
                <h2 class="error-title">Horário Inválido</h2>
                <p class="error-message">
                    A campanha terminaria às <strong>${endTime}</strong>
                    <br>
                    Horário comercial: até <strong>${commercialEnd}</strong>
                </p>
                <p class="error-suggestion">
                    Tente:
                    <br>
                    • Escolher um horário de início mais cedo
                    <br>
                    • Reduzir o número de leads
                </p>
                <button class="error-close-btn" onclick="closeLimitError()">
                    Entendi
                </button>
            </div>
        </div>
    `;

    const modalContainer = document.createElement('div');
    modalContainer.id = 'limitErrorModal';
    modalContainer.className = 'error-modal-overlay';
    modalContainer.innerHTML = errorHtml;

    document.body.appendChild(modalContainer);

    setTimeout(() => {
        modalContainer.classList.add('active');
    }, 10);
}

/**
 * Mostra/esconde seções da interface baseado no estado
 * @param {string} section - Nome da seção
 * @param {boolean} show - True para mostrar, false para esconder
 */
function toggleSection(section, show) {
    const element = document.getElementById(section);
    if (element) {
        element.style.display = show ? 'block' : 'none';

        if (show) {
            element.classList.add('fade-in');
        }
    }
}

/**
 * Limpa a timeline e resumo
 */
function clearTimeline() {
    const tbody = document.getElementById('timelineBody');
    if (tbody) {
        tbody.innerHTML = '';
    }

    updateElement('startTime', '-');
    updateElement('endTime', '-');
    updateElement('duration', '-');

    console.log('🧹 Timeline limpa');
}

/**
 * Anima a renderização da timeline
 */
function animateTimelineRender() {
    const timelineSection = document.getElementById('campaignTimeline');
    if (timelineSection) {
        timelineSection.classList.add('slide-in');
    }
}

// ==================== FUNÇÕES DE UTILIDADE ====================

/**
 * Formata número com separador de milhares (reutiliza do calculator)
 * @param {number} num - Número a formatar
 * @returns {string} Número formatado
 */
function formatNumber(num) {
    return num.toLocaleString('pt-BR');
}

/**
 * Formata duração (reutiliza do calculator)
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
 * Agrupa intervalos em blocos (reutiliza do calculator se disponível)
 * Fallback caso capacity-calculator não esteja carregado
 */
function groupIntervalsToHours(intervalos) {
    // Tenta usar a função do calculator se disponível
    if (typeof window.groupIntervalsToHours === 'function') {
        return window.groupIntervalsToHours(intervalos);
    }

    // Fallback: implementação local
    const hoursBlocks = [];

    for (let i = 0; i < intervalos.length; i += 2) {
        const first = intervalos[i];
        const second = intervalos[i + 1];

        if (second) {
            hoursBlocks.push({
                inicio: first.inicio,
                fim: second.fim,
                ligacoes: first.ligacoes + second.ligacoes,
                isFull: first.isFull && second.isFull
            });
        } else {
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

// ==================== ANIMAÇÕES CSS (via JS) ====================

/**
 * Adiciona estilos de animação dinamicamente
 */
function injectAnimationStyles() {
    if (document.getElementById('timeline-animations')) {
        return; // Já injetado
    }

    const style = document.createElement('style');
    style.id = 'timeline-animations';
    style.textContent = `
        @keyframes slideInRow {
            from {
                opacity: 0;
                transform: translateX(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .fade-in {
            animation: fadeIn 0.5s ease-out;
        }

        .slide-in {
            animation: slideInRow 0.6s ease-out;
        }
    `;

    document.head.appendChild(style);
}

// Injeta animações ao carregar
injectAnimationStyles();

console.log('✅ Timeline Renderer carregado com sucesso');
