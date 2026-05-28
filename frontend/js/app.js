const API = 'http://localhost:3000/api';

// ──────────────────────────────────────────────────────────────
//  Utilitários
// ──────────────────────────────────────────────────────────────

const $ = id => document.getElementById(id);

function moeda(v) {
    return Number(v || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function dataHora(iso) {
    if (!iso) return '–';
    return new Date(iso).toLocaleString('pt-BR');
}

async function get(path) {
    const r = await fetch(API + path);
    return r.json();
}

async function post(path, body) {
    const r = await fetch(API + path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
    });
    return r.json();
}

function alerta(elId, texto, tipo = 'success') {
    $(elId).innerHTML =
        `<div class="alert alert-${tipo} mt-2">${texto}</div>`;
    setTimeout(() => $(elId).innerHTML = '', 4000);
}

// ──────────────────────────────────────────────────────────────
//  Navegação entre abas
// ──────────────────────────────────────────────────────────────

const tabCarregadores = {
    dashboard:    carregarDashboard,
    computadores: carregarComputadores,
    sessoes:      carregarSessoes,
    clientes:     carregarClientes,
    produtos:     carregarProdutos,
    caixa:        carregarCaixa,
};

document.querySelectorAll('#abas .nav-link').forEach(link => {
    link.addEventListener('click', e => {
        e.preventDefault();
        document.querySelectorAll('#abas .nav-link').forEach(l => l.classList.remove('active'));
        link.classList.add('active');
        document.querySelectorAll('.tab-content').forEach(t => t.classList.add('d-none'));
        const tab = link.dataset.tab;
        $('tab-' + tab).classList.remove('d-none');
        tabCarregadores[tab]();
    });
});

// Subtabs de clientes
document.querySelectorAll('#tabs-clientes .nav-link').forEach(link => {
    link.addEventListener('click', e => {
        e.preventDefault();
        document.querySelectorAll('#tabs-clientes .nav-link').forEach(l => l.classList.remove('active'));
        link.classList.add('active');
        const sub = link.dataset.subtab;
        $('lista-clientes-content').classList.add('d-none');
        $('ranking-clientes-content').classList.add('d-none');
        $(sub + '-content').classList.remove('d-none');
        if (sub === 'ranking-clientes') carregarRankingClientes();
    });
});

// ──────────────────────────────────────────────────────────────
//  Relógio
// ──────────────────────────────────────────────────────────────

function atualizarRelogio() {
    $('relogio').textContent = new Date().toLocaleString('pt-BR');
}
setInterval(atualizarRelogio, 1000);
atualizarRelogio();

// ──────────────────────────────────────────────────────────────
//  DASHBOARD
// ──────────────────────────────────────────────────────────────

async function carregarDashboard() {
    const [computadores, ativas] = await Promise.all([
        get('/computadores'),
        get('/sessoes/ativas')
    ]);

    $('kpi-disponiveis').textContent = computadores.filter(c => c.status === 'disponivel').length;
    $('kpi-ocupados').textContent    = computadores.filter(c => c.status === 'ocupado').length;
    $('kpi-manutencao').textContent  = computadores.filter(c => c.status === 'manutencao').length;

    const receitaAberta = ativas.reduce((s, a) => s + Number(a.valor_parcial || 0), 0);
    $('kpi-receita').textContent = moeda(receitaAberta);

    $('tabela-ativas-container').innerHTML = tabelaSessoesAtivas(ativas);
}

function tabelaSessoesAtivas(ativas) {
    if (!ativas.length) return '<p class="text-muted">Nenhuma sessão ativa no momento.</p>';
    const linhas = ativas.map(s => `
        <tr>
            <td>${s.id_sessao}</td>
            <td>${s.cliente}</td>
            <td>PC ${s.computador}</td>
            <td>${dataHora(s.inicio)}</td>
            <td>${s.minutos_em_uso} min</td>
            <td>${moeda(s.valor_parcial)}</td>
        </tr>`).join('');
    return `
        <table class="table table-hover table-bordered">
            <thead>
                <tr><th>#</th><th>Cliente</th><th>PC</th><th>Início</th><th>Duração</th><th>Parcial</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

// ──────────────────────────────────────────────────────────────
//  COMPUTADORES
// ──────────────────────────────────────────────────────────────

async function carregarComputadores() {
    const computadores = await get('/computadores');
    $('computadores-grid').innerHTML = computadores.map(c => `
        <div class="col-md-4 col-lg-3">
            <div class="pc-card ${c.status}">
                <div class="numero">PC ${c.numero}</div>
                <div class="small mb-2">${c.descricao}</div>
                <div class="fw-bold">${moeda(c.valor_hora)}/h</div>
                <span class="badge bg-dark bg-opacity-25 mt-2 text-capitalize">${c.status}</span>
            </div>
        </div>`).join('');
}

// ──────────────────────────────────────────────────────────────
//  SESSÕES
// ──────────────────────────────────────────────────────────────

async function carregarSessoes() {
    const [clientes, disponiveis, ativas, historico] = await Promise.all([
        get('/clientes'),
        get('/computadores/disponiveis'),
        get('/sessoes/ativas'),
        get('/sessoes/historico')
    ]);

    $('sel-cliente-sessao').innerHTML = clientes
        .map(c => `<option value="${c.id_cliente}">${c.nome}</option>`).join('');

    $('sel-computador-sessao').innerHTML = disponiveis
        .map(c => `<option value="${c.id_computador}">PC ${c.numero} – ${moeda(c.valor_hora)}/h</option>`).join('');

    $('sel-sessao-fechar').innerHTML = ativas
        .map(s => `<option value="${s.id_sessao}">#${s.id_sessao} – ${s.cliente} / PC ${s.computador}</option>`).join('');

    $('historico-container').innerHTML = tabelaHistorico(historico);
}

function tabelaHistorico(historico) {
    if (!historico.length) return '<p class="text-muted">Sem histórico.</p>';
    const linhas = historico.map(s => `
        <tr>
            <td>${s.id_sessao}</td>
            <td>${s.cliente}</td>
            <td>PC ${s.computador}</td>
            <td>${dataHora(s.inicio)}</td>
            <td>${dataHora(s.fim)}</td>
            <td>${moeda(s.valor_total)}</td>
            <td><span class="badge ${s.status === 'aberta' ? 'bg-success' : 'bg-secondary'}">${s.status}</span></td>
        </tr>`).join('');
    return `
        <table class="table table-sm table-bordered">
            <thead>
                <tr><th>#</th><th>Cliente</th><th>PC</th><th>Início</th><th>Fim</th><th>Valor</th><th>Status</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

async function abrirSessao() {
    const id_cliente    = $('sel-cliente-sessao').value;
    const id_computador = $('sel-computador-sessao').value;
    const r = await post('/sessoes/abrir', { id_cliente, id_computador });
    if (r.error) alerta('msg-sessao', r.error, 'danger');
    else {
        alerta('msg-sessao', r.message);
        carregarSessoes();
        carregarDashboard();
    }
}

async function fecharSessao() {
    const id = $('sel-sessao-fechar').value;
    if (!id) return alerta('msg-fechar', 'Nenhuma sessão ativa selecionada.', 'warning');
    const r = await post(`/sessoes/fechar/${id}`, {});
    if (r.error) alerta('msg-fechar', r.error, 'danger');
    else {
        alerta('msg-fechar', `${r.message} Total: ${moeda(r.valor_total)}`);
        carregarSessoes();
        carregarDashboard();
    }
}

// ──────────────────────────────────────────────────────────────
//  CLIENTES
// ──────────────────────────────────────────────────────────────

async function carregarClientes() {
    const clientes = await get('/clientes');
    const linhas = clientes.map(c => `
        <tr>
            <td>${c.id_cliente}</td>
            <td>${c.nome}</td>
            <td>${c.email}</td>
            <td>${c.telefone || '–'}</td>
            <td>${moeda(c.saldo_creditos)}</td>
            <td>${dataHora(c.data_cadastro)}</td>
        </tr>`).join('');
    $('lista-clientes-content').innerHTML = `
        <table class="table table-hover table-bordered">
            <thead>
                <tr><th>#</th><th>Nome</th><th>E-mail</th><th>Telefone</th><th>Saldo</th><th>Cadastro</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

async function carregarRankingClientes() {
    const ranking = await get('/clientes/ranking');
    const linhas = ranking.map((c, i) => `
        <tr>
            <td><strong>${i + 1}º</strong></td>
            <td>${c.nome}</td>
            <td>${c.total_sessoes}</td>
            <td>${moeda(c.total_gasto)}</td>
            <td>${moeda(c.gasto_medio)}</td>
        </tr>`).join('');
    $('ranking-clientes-content').innerHTML = `
        <table class="table table-hover table-bordered">
            <thead>
                <tr><th>Pos.</th><th>Cliente</th><th>Sessões</th><th>Total Gasto</th><th>Gasto Médio</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

async function cadastrarCliente() {
    const nome     = $('inp-nome-cliente').value.trim();
    const email    = $('inp-email-cliente').value.trim();
    const telefone = $('inp-tel-cliente').value.trim();
    const r = await post('/clientes', { nome, email, telefone });
    if (r.error) alerta('msg-cliente', r.error, 'danger');
    else {
        alerta('msg-cliente', r.message);
        ['inp-nome-cliente','inp-email-cliente','inp-tel-cliente'].forEach(id => $(id).value = '');
        carregarClientes();
    }
}

// ──────────────────────────────────────────────────────────────
//  PRODUTOS
// ──────────────────────────────────────────────────────────────

async function carregarProdutos() {
    const [produtos, ativas] = await Promise.all([
        get('/produtos'),
        get('/sessoes/ativas')
    ]);

    $('sel-sessao-venda').innerHTML = ativas
        .map(s => `<option value="${s.id_sessao}">#${s.id_sessao} – ${s.cliente}</option>`).join('');

    $('sel-produto-venda').innerHTML = produtos
        .map(p => `<option value="${p.id_produto}">${p.nome} – ${moeda(p.preco)} (estoque: ${p.estoque})</option>`).join('');

    const linhas = produtos.map(p => `
        <tr>
            <td>${p.id_produto}</td>
            <td>${p.nome}</td>
            <td>${p.categoria}</td>
            <td>${moeda(p.preco)}</td>
            <td>
                <span class="badge ${p.estoque > 10 ? 'bg-success' : p.estoque > 0 ? 'bg-warning text-dark' : 'bg-danger'}">
                    ${p.estoque}
                </span>
            </td>
        </tr>`).join('');
    $('produtos-container').innerHTML = `
        <table class="table table-hover table-bordered">
            <thead>
                <tr><th>#</th><th>Produto</th><th>Categoria</th><th>Preço</th><th>Estoque</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

async function registrarVenda() {
    const id_sessao  = $('sel-sessao-venda').value;
    const id_produto = $('sel-produto-venda').value;
    const quantidade = Number($('inp-qtd-venda').value);
    if (!id_sessao) return alerta('msg-venda', 'Selecione uma sessão ativa.', 'warning');
    const r = await post('/produtos/vender', { id_sessao, id_produto, quantidade });
    if (r.error) alerta('msg-venda', r.error, 'danger');
    else {
        alerta('msg-venda', r.message);
        carregarProdutos();
    }
}

// ──────────────────────────────────────────────────────────────
//  CAIXA
// ──────────────────────────────────────────────────────────────

async function carregarCaixa() {
    const [resumo, lancamentos] = await Promise.all([
        get('/caixa/resumo'),
        get('/caixa')
    ]);

    let entradas = 0, saidas = 0;
    resumo.forEach(r => {
        if (r.tipo === 'entrada') entradas = Number(r.total);
        else saidas = Number(r.total);
    });
    $('caixa-entradas').textContent = moeda(entradas);
    $('caixa-saidas').textContent   = moeda(saidas);
    $('caixa-saldo').textContent    = moeda(entradas - saidas);

    const linhas = lancamentos.map(l => `
        <tr>
            <td>${l.id_auditoria}</td>
            <td><span class="badge ${l.tipo === 'entrada' ? 'bg-success' : 'bg-danger'}">${l.tipo}</span></td>
            <td>${moeda(l.valor)}</td>
            <td>${l.descricao}</td>
            <td>${dataHora(l.data_hora)}</td>
        </tr>`).join('');
    $('caixa-container').innerHTML = `
        <table class="table table-sm table-bordered">
            <thead>
                <tr><th>#</th><th>Tipo</th><th>Valor</th><th>Descrição</th><th>Data/Hora</th></tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>`;
}

// ──────────────────────────────────────────────────────────────
//  Inicialização
// ──────────────────────────────────────────────────────────────

carregarDashboard();
