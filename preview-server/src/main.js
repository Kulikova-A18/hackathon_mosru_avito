import { createApp } from 'vue'

const app = createApp({
    data() {
        return {
            loading: false,
            error: null,
            screenConfig: null,
            screenSlug: null,
            currentUrl: window.location.href,
            backendStatus: 'checking...',
            debugInfo: null,
            availableScreens: []
        }
    },
    async mounted() {
        await this.checkBackendConnection()
        await this.loadAvailableScreens()
        await this.loadScreenPreview()
    },
    methods: {
        async checkBackendConnection() {
            try {
                const response = await fetch('http://localhost:8080/api/health')
                if (response.ok) {
                    this.backendStatus = 'connected ✅'
                } else {
                    this.backendStatus = 'error ❌'
                }
            } catch (err) {
                this.backendStatus = 'offline ❌'
            }
        },

        async loadAvailableScreens() {
            try {
                const response = await fetch('http://localhost:8080/api/debug/screens')
                if (response.ok) {
                    const data = await response.json()
                    this.availableScreens = data.screens.filter(screen => screen.is_active)
                    console.log('Available screens:', this.availableScreens)
                }
            } catch (err) {
                console.error('Error loading available screens:', err)
            }
        },

        async loadScreen(slug) {
            // Update URL without page reload
            const newUrl = `${window.location.origin}${window.location.pathname}?screen=${slug}`
            window.history.pushState({}, '', newUrl)
            this.currentUrl = newUrl
            this.screenSlug = slug
            await this.loadScreenPreview()
        },

        async loadScreenPreview() {
            try {
                this.loading = true
                this.error = null
                this.screenConfig = null
                this.debugInfo = 'Начинаем загрузку...'

                // Получаем screen slug из URL параметров
                const urlParams = new URLSearchParams(window.location.search)
                this.screenSlug = urlParams.get('screen')
                
                this.debugInfo = `Screen slug: ${this.screenSlug}`
                
                if (!this.screenSlug) {
                    this.loading = false
                    return
                }

                this.debugInfo = `Загружаем экран: ${this.screenSlug}`
                
                // Загружаем конфигурацию экрана с бэкенда
                const response = await fetch(`http://localhost:8080/api/screens/slug/${this.screenSlug}`)
                
                this.debugInfo = `Статус ответа: ${response.status}`
                
                if (!response.ok) {
                    if (response.status === 404) {
                        throw new Error(`Экран с slug "${this.screenSlug}" не найден. Проверьте правильность написания.`)
                    } else {
                        throw new Error(`Ошибка сервера: ${response.status}`)
                    }
                }

                this.screenConfig = await response.json()
                this.debugInfo = `Экран получен: ${this.screenConfig.name}`
                
                // Ensure config is properly parsed
                if (this.screenConfig.config && typeof this.screenConfig.config === 'string') {
                    try {
                        this.screenConfig.config = JSON.parse(this.screenConfig.config)
                        console.log('Config parsed from string in frontend')
                    } catch (parseError) {
                        console.error('Error parsing config in frontend:', parseError)
                    }
                }
                
                console.log('Screen config loaded:', this.screenConfig)
                
                // Даем время Vue обновиться перед рендерингом
                await this.$nextTick()
                this.renderScreenContent()
                
            } catch (err) {
                this.error = err.message
                console.error('Preview error:', err)
                this.debugInfo = `Ошибка: ${err.message}`
            } finally {
                this.loading = false
            }
        },

        renderScreenContent() {
            if (!this.screenConfig?.config) {
                console.warn('No screen config found:', this.screenConfig)
                const container = document.getElementById('screen-content')
                if (container) {
                    container.innerHTML = `
                        <div class="error">
                            <h3>Конфигурация экрана не найдена</h3>
                            <p>Экран "${this.screenConfig?.name}" не содержит конфигурации компонентов.</p>
                            <div class="debug-info">
                                Screen Data: ${JSON.stringify(this.screenConfig, null, 2)}
                            </div>
                        </div>
                    `
                }
                return
            }
            
            const container = document.getElementById('screen-content')
            if (!container) {
                console.error('Screen content container not found')
                return
            }

            try {
                // Очищаем контейнер
                container.innerHTML = ''

                // Динамически рендерим компоненты на основе конфигурации
                const config = this.screenConfig.config
                console.log('Rendering screen config:', config)
                
                if (config.components && Array.isArray(config.components) && config.components.length > 0) {
                    config.components.forEach((component, index) => {
                        const element = this.createComponentElement(component, index)
                        container.appendChild(element)
                    })
                } else {
                    container.innerHTML = `
                        <div class="component">
                            <div style="text-align: center; color: #666; padding: 40px;">
                                <h3>Нет компонентов для отображения</h3>
                                <p>Конфигурация экрана не содержит компонентов</p>
                                <div class="debug-info">
                                    Config: ${JSON.stringify(config, null, 2)}
                                </div>
                            </div>
                        </div>
                    `
                }

                console.log('Preview загружен успешно:', this.screenConfig.name)
            } catch (err) {
                console.error('Ошибка рендеринга:', err)
                this.error = 'Ошибка отображения preview: ' + err.message
            }
        },

        createComponentElement(component, index) {
            const element = document.createElement('div')
            element.className = `component component-${component.type}`
            element.setAttribute('data-component-type', component.type)
            element.setAttribute('data-component-index', index)

            // Базовый рендеринг по типу компонента
            switch (component.type) {
                case 'header':
                    element.innerHTML = `
                        <div class="component-header">
                            <h1 style="margin: 0; color: #2d3748; font-size: 2em;">${component.props?.text || 'Заголовок'}</h1>
                            ${component.props?.subtitle ? `<p style="margin: 10px 0 0 0; color: #718096; font-size: 1.2em;">${component.props.subtitle}</p>` : ''}
                        </div>
                    `
                    break
                case 'text':
                    element.innerHTML = `
                        <div style="color: #4a5568; line-height: 1.6; font-size: 16px;">
                            ${component.props?.text || 'Текстовый контент'}
                        </div>
                    `
                    break
                case 'button':
                    element.innerHTML = `
                        <button class="component-button">
                            ${component.props?.text || 'Кнопка'}
                        </button>
                    `
                    break
                case 'input':
                    element.innerHTML = `
                        <input 
                            class="component-input" 
                            type="${component.props?.type || 'text'}" 
                            placeholder="${component.props?.placeholder || 'Введите текст...'}"
                            value="${component.props?.value || ''}"
                        >
                    `
                    break
                case 'card':
                    element.innerHTML = `
                        <div style="border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; background: white;">
                            <h3 style="margin: 0 0 15px 0; color: #2d3748;">${component.props?.title || 'Карточка'}</h3>
                            <p style="margin: 0; color: #718096; white-space: pre-line;">${component.props?.content || 'Содержимое карточки'}</p>
                        </div>
                    `
                    break
                default:
                    element.innerHTML = `
                        <div style="text-align: center; color: #a0aec0; padding: 20px;">
                            <div style="font-size: 2em;">🔧</div>
                            <h4 style="margin: 10px 0; color: #718096;">Компонент: ${component.type}</h4>
                            <div class="debug-info" style="font-size: 12px; margin-top: 10px;">
                                ${JSON.stringify(component.props, null, 2)}
                            </div>
                        </div>
                    `
            }

            return element
        },

        retryLoading() {
            this.loadScreenPreview()
        }
    }
})

app.mount('#app')
